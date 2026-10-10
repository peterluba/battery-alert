import Foundation
import IOKit.ps

struct BatteryStatus: Equatable {
    var percent: Int
    var isPluggedIn: Bool
}

/// Reads battery percentage and power-source state from IOKit and reports
/// changes via `onChange`. Uses IOPS run-loop notifications plus a periodic
/// timer as a safety net. Runs on the main actor (its run-loop source and
/// timer are both installed on the main run loop).
@MainActor
final class BatteryMonitor {
    var onChange: ((BatteryStatus) -> Void)?

    private var runLoopSource: CFRunLoopSource?
    private var timer: Timer?
    private(set) var current: BatteryStatus?

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let source = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            MainActor.assumeIsolated {
                Unmanaged<BatteryMonitor>.fromOpaque(ctx).takeUnretainedValue().poll()
            }
        }, context)?.takeRetainedValue() {
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        poll()
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
        runLoopSource = nil
        timer?.invalidate()
        timer = nil
    }

    func poll() {
        guard let status = Self.read() else { return }
        if status != current {
            current = status
            onChange?(status)
        }
    }

    static func read() -> BatteryStatus? {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue()
                    as? [String: Any] else { continue }

            let current = desc[kIOPSCurrentCapacityKey as String] as? Int
            let max = desc[kIOPSMaxCapacityKey as String] as? Int
            let state = desc[kIOPSPowerSourceStateKey as String] as? String

            guard let current, let max, max > 0 else { continue }

            let percent = Int((Double(current) / Double(max) * 100).rounded())
            let pluggedIn = (state == (kIOPSACPowerValue as String))
            return BatteryStatus(percent: percent, isPluggedIn: pluggedIn)
        }
        return nil
    }
}
