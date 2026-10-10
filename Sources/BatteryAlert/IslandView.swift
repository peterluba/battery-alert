import SwiftUI

struct IslandView: View {
    let controller: AlertController
    let notch: NotchInfo
    let onDismiss: () -> Void

    @State private var breathe = false

    private var state: AlertState { controller.state }
    private var isVisible: Bool { state != .hidden }

    var body: some View {
        VStack(spacing: 0) {
            pill
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.all)
        .onChange(of: state, initial: true) { _, newValue in
            syncBreathing(newValue)
        }
    }

    // MARK: Pill

    private var pill: some View {
        let m = metrics(for: state)
        let shape = NotchPillShape(topRadius: m.topRadius, bottomRadius: m.radius)
        return shape
            .fill(Color.black)
            .frame(width: m.width, height: m.height)
            .overlay { topHighlight(shape) }
            .overlay {
                content
                    .scaleEffect(isVisible ? 1 : 0.5, anchor: .center)
                    .opacity(isVisible ? 1 : 0)
            }
            .clipShape(shape)
            // The black body's frame animates between the notch footprint (hidden)
            // and the full pill (visible), so it stretches out of / retracts into
            // the notch itself — solid black the entire time.
            .scaleEffect(breathe && isWarning ? 1.012 : 1.0, anchor: .top)
            .contentShape(shape)
            .onTapGesture { onDismiss() }
            .animation(showHideAnimation, value: state)
            .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: breathe)
    }

    /// Bouncy on open; softer and a touch slower on dismiss.
    private var showHideAnimation: Animation {
        state == .hidden
            ? .spring(response: 0.6, dampingFraction: 0.92)
            : .spring(response: 0.5, dampingFraction: 0.62)
    }

    private func topHighlight(_ shape: NotchPillShape) -> some View {
        shape
            .fill(
                LinearGradient(
                    colors: [.white.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .allowsHitTesting(false)
    }

    // MARK: Content (centered icon + title, no subtitle)

    private var content: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.top, notch.height * 0.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .allowsHitTesting(false)
    }

    // MARK: State-derived values

    private struct Metrics { var width: CGFloat; var height: CGFloat; var radius: CGFloat; var topRadius: CGFloat }

    private func metrics(for state: AlertState) -> Metrics {
        switch state {
        case .hidden:
            // Zero height → invisible at rest. Start the stretch at the notch's
            // visible width so it widens + drops out of the notch (rather than a
            // full-width bar sliding down from the top edge).
            return Metrics(width: notch.width * 0.7, height: 0, radius: 24, topRadius: 11)
        case .warning:
            return Metrics(width: 300, height: 74, radius: 24, topRadius: 11)
        case .charging:
            return Metrics(width: 300, height: 74, radius: 24, topRadius: 11)
        }
    }

    private var isWarning: Bool { if case .warning = state { return true }; return false }
    private var isLevel1: Bool { state == .warning(level: 1) }
    private var isCharging: Bool { state == .charging }

    private var iconName: String {
        isCharging ? "bolt.fill" : "battery.0percent"
    }

    private var iconColor: Color {
        switch state {
        case .charging: return .green
        case .warning(let level): return level == 1 ? Color(red: 1.0, green: 0.18, blue: 0.18) : .red
        case .hidden: return .clear
        }
    }

    private var title: String {
        switch state {
        case .charging: return "Charging"
        case .warning(let level): return "Battery at \(level)%"
        case .hidden: return ""
        }
    }

    private func syncBreathing(_ state: AlertState) {
        breathe = { if case .warning = state { return true }; return false }()
    }
}

/// Pill shape matching the MacBook notch: a flat full-width top edge that flares
/// outward into the body via concave fillets at the top corners (top-leading /
/// top-trailing), with normal convex rounding at the bottom corners.
struct NotchPillShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set { topRadius = newValue.first; bottomRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let tr = max(0, min(topRadius, w / 2, h / 2))
        let br = max(0, min(bottomRadius, w / 2 - tr, h - tr))

        var p = Path()
        // Flat top edge, full width (the lip that meets the screen's top bezel).
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: w, y: 0))
        // Concave fillet flaring inward to the right body side.
        p.addQuadCurve(to: CGPoint(x: w - tr, y: tr), control: CGPoint(x: w - tr, y: 0))
        // Right side down.
        p.addLine(to: CGPoint(x: w - tr, y: h - br))
        // Convex bottom-right corner.
        p.addQuadCurve(to: CGPoint(x: w - tr - br, y: h), control: CGPoint(x: w - tr, y: h))
        // Bottom edge.
        p.addLine(to: CGPoint(x: tr + br, y: h))
        // Convex bottom-left corner.
        p.addQuadCurve(to: CGPoint(x: tr, y: h - br), control: CGPoint(x: tr, y: h))
        // Left side up.
        p.addLine(to: CGPoint(x: tr, y: tr))
        // Concave fillet flaring outward to the top-left lip.
        p.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: tr, y: 0))
        p.closeSubpath()
        return p
    }
}
