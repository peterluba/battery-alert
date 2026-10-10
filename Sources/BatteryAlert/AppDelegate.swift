import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = AlertController()
    private let monitor = BatteryMonitor()
    private var statusItem: NSStatusItem?
    private var overlay: NotchOverlayWindow?
    private var loginItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let notch = NotchInfo.current()
        let window = NotchOverlayWindow(controller: controller, notch: notch) { [weak self] in
            self?.controller.dismissByClick()
        }
        window.orderFrontRegardless()
        overlay = window

        controller.onStateChange = { [weak self] state in
            self?.overlay?.setInteractive(state != .hidden)
        }

        monitor.onChange = { [weak self] status in
            self?.controller.update(status)
        }
        monitor.start()

        setUpStatusItem()

        // Verification hook: BATTERYALERT_VERIFY=2|1|charging shows that state
        // immediately and runs as a foreground app so it can be screenshotted.
        if let verify = ProcessInfo.processInfo.environment["BATTERYALERT_VERIFY"] {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            switch verify {
            case "1": controller.previewWarning(level: 1)
            case "charging": controller.previewCharging()
            default: controller.previewWarning(level: 2)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    // MARK: Status item

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "battery.25percent",
            accessibilityDescription: "Battery Alert"
        )

        let menu = NSMenu()
        menu.addItem(menuItem("Preview 2% Alert", #selector(preview2)))
        menu.addItem(menuItem("Preview 1% Alert", #selector(preview1)))
        menu.addItem(menuItem("Preview Charging", #selector(previewCharging)))
        menu.addItem(.separator())
        menu.addItem(menuItem("Dismiss Alert", #selector(dismissAlert)))
        menu.addItem(.separator())

        let login = menuItem("Launch at Login", #selector(toggleLoginItem))
        loginItem = login
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(menuItem("Quit Battery Alert", #selector(quit)))

        item.menu = menu
        statusItem = item
        refreshLoginItemState()
    }

    private func menuItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    // MARK: Menu actions

    @objc private func preview2() { controller.previewWarning(level: 2) }
    @objc private func preview1() { controller.previewWarning(level: 1) }
    @objc private func previewCharging() { controller.previewCharging() }
    @objc private func dismissAlert() { controller.forceHide() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func toggleLoginItem() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSLog("Battery Alert: login item toggle failed: \(error)")
        }
        refreshLoginItemState()
    }

    private func refreshLoginItemState() {
        loginItem?.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
    }
}
