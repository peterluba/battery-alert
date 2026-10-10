import AppKit
import Observation

enum AlertState: Equatable {
    case hidden
    case warning(level: Int)   // 2 or 1
    case charging
}

@MainActor
@Observable
final class AlertController {
    private(set) var state: AlertState = .hidden

    /// Fired whenever `state` changes, so the host window can toggle click-through.
    var onStateChange: ((AlertState) -> Void)?

    // Per-discharge-cycle latches so each threshold fires at most once until
    // the next time the machine is plugged in.
    private var shown2 = false
    private var shown1 = false
    private var lastPluggedIn: Bool?

    private var chargingDismiss: DispatchWorkItem?

    private let chargingVisibleSeconds: TimeInterval = 3

    // MARK: Battery-driven updates

    func update(_ status: BatteryStatus) {
        let wasPlugged = lastPluggedIn
        lastPluggedIn = status.isPluggedIn

        if status.isPluggedIn {
            // Re-arm thresholds for the next discharge cycle.
            shown2 = false
            shown1 = false
            // Show the charging pill only on the rising edge (not at launch).
            if wasPlugged == false {
                showCharging()
            }
            return
        }

        // On battery.
        if status.percent <= 1, !shown1 {
            shown1 = true
            setState(.warning(level: 1))
        } else if status.percent <= 2, !shown2 {
            shown2 = true
            setState(.warning(level: 2))
        }
    }

    // MARK: Interaction

    /// User clicked the pill. Dismisses the current alert with haptic feedback.
    func dismissByClick() {
        guard state != .hidden else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        setState(.hidden)
    }

    // MARK: Charging

    private func showCharging() {
        setState(.charging)
        scheduleChargingDismiss()
    }

    private func scheduleChargingDismiss() {
        chargingDismiss?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.state == .charging else { return }
            self.setState(.hidden)
        }
        chargingDismiss = work
        DispatchQueue.main.asyncAfter(deadline: .now() + chargingVisibleSeconds, execute: work)
    }

    // MARK: Preview (menu-bar triggers, bypass battery logic)

    func previewWarning(level: Int) {
        chargingDismiss?.cancel()
        setState(.warning(level: level))
    }

    func previewCharging() {
        showCharging()
    }

    func forceHide() {
        chargingDismiss?.cancel()
        setState(.hidden)
    }

    // MARK: Helpers

    private func setState(_ newState: AlertState) {
        guard newState != state else { return }
        state = newState
        onStateChange?(newState)
    }
}
