import AppKit

/// Describes the notch (or a synthetic top-center fallback) on the active
/// built-in display, in AppKit global screen coordinates (bottom-left origin).
struct NotchInfo {
    var screen: NSScreen
    var width: CGFloat
    var height: CGFloat
    var centerX: CGFloat
    var topY: CGFloat        // screen.frame.maxY — the very top edge
    var hasNotch: Bool

    static func current() -> NotchInfo {
        let screen = builtInScreen() ?? NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.frame
        let insetTop = screen.safeAreaInsets.top

        if insetTop > 0,
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let width = max(right.minX - left.maxX, 120)
            let centerX = left.maxX + width / 2
            return NotchInfo(screen: screen,
                             width: width,
                             height: insetTop,
                             centerX: centerX,
                             topY: frame.maxY,
                             hasNotch: true)
        }

        // Fallback: synthetic notch centered at the top of the screen.
        return NotchInfo(screen: screen,
                         width: 190,
                         height: 32,
                         centerX: frame.midX,
                         topY: frame.maxY,
                         hasNotch: false)
    }

    private static func builtInScreen() -> NSScreen? {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 }
            ?? NSScreen.screens.first { screen in
                guard let number = screen.deviceDescription[.init("NSScreenNumber")] as? CGDirectDisplayID
                else { return false }
                return CGDisplayIsBuiltin(number) != 0
            }
    }
}
