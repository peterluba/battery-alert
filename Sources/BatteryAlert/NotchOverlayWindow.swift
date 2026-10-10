import AppKit
import SwiftUI

/// Borderless, non-activating panel pinned over the notch. Hosts the SwiftUI
/// island. While an alert is showing it only intercepts the mouse when the
/// cursor is actually over the pill, so windows elsewhere (including directly
/// under the notch, beside the pill) stay fully draggable / clickable.
final class NotchOverlayWindow: NSPanel {
    static let canvasSize = CGSize(width: 760, height: 320)
    /// Generous bounds around the visible pill (covers bounce/breathing overshoot).
    private static let pillHitSize = CGSize(width: 330, height: 92)

    private var pillScreenRect: CGRect = .zero
    private var alertVisible = false
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(controller: AlertController, notch: NotchInfo, onDismiss: @escaping () -> Void) {
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.canvasSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) - 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = true
        isMovable = false
        isFloatingPanel = true
        hidesOnDeactivate = false

        let root = IslandView(controller: controller, notch: notch, onDismiss: onDismiss)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = NSRect(origin: .zero, size: Self.canvasSize)
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting

        position(for: notch)

        // Pill's max footprint in global screen coordinates (top-centered on the notch).
        pillScreenRect = CGRect(
            x: notch.centerX - Self.pillHitSize.width / 2,
            y: notch.topY - Self.pillHitSize.height,
            width: Self.pillHitSize.width,
            height: Self.pillHitSize.height
        )
    }

    deinit { teardownMonitors() }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Prevent AppKit from pushing the window below the menu bar — we want it
    /// flush with the physical top edge so it merges with the notch.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    private func position(for notch: NotchInfo) {
        let origin = NSPoint(
            x: notch.centerX - Self.canvasSize.width / 2,
            y: notch.topY - Self.canvasSize.height
        )
        setFrame(NSRect(origin: origin, size: Self.canvasSize), display: true)
    }

    /// Begin/stop intercepting clicks. Even while "interactive", only the area
    /// over the pill itself is hit — the rest of the window stays click-through.
    func setInteractive(_ interactive: Bool) {
        alertVisible = interactive
        if interactive {
            startMonitors()
            updateClickThrough()
        } else {
            teardownMonitors()
            ignoresMouseEvents = true
        }
    }

    private func startMonitors() {
        if globalMonitor == nil {
            // Fires while the cursor is over OTHER apps (window is click-through).
            globalMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.mouseMoved, .leftMouseDragged]
            ) { [weak self] _ in self?.updateClickThrough() }
        }
        if localMonitor == nil {
            // Fires while the cursor is over our pill (window is interactive),
            // so we notice when it leaves again.
            localMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.mouseMoved, .leftMouseDragged]
            ) { [weak self] event in
                self?.updateClickThrough()
                return event
            }
        }
    }

    private func teardownMonitors() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func updateClickThrough() {
        guard alertVisible else { ignoresMouseEvents = true; return }
        ignoresMouseEvents = !pillScreenRect.contains(NSEvent.mouseLocation)
    }
}
