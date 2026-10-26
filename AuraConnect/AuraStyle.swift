import SwiftUI

enum AuraTheme {
    static let auraBlue       = Color(red: 0.36, green: 0.78, blue: 1.00)
    static let auraBlueDeep   = Color(red: 0.10, green: 0.42, blue: 0.92)
    static let bgBase         = Color(red: 0.04, green: 0.05, blue: 0.07)
    static let panelBase      = Color.white.opacity(0.04)
    static let panelStroke    = Color.white.opacity(0.08)
    static let textPrimary    = Color.white
    static let textDim        = Color.white.opacity(0.62)
    static let textFaint      = Color.white.opacity(0.38)
    static let okGreen        = Color(red: 0.36, green: 0.92, blue: 0.62)
    static let warnAmber      = Color(red: 1.00, green: 0.74, blue: 0.32)
    static let errRed         = Color(red: 1.00, green: 0.40, blue: 0.42)
}

enum AuraFont {
    static func regular(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .default) }
    static func medium(_ size: CGFloat)  -> Font { .system(size: size, weight: .medium,  design: .default) }
    static func semi(_ size: CGFloat)    -> Font { .system(size: size, weight: .semibold, design: .default) }
    static func mono(_ size: CGFloat)    -> Font { .system(size: size, weight: .regular, design: .monospaced) }
}

extension View {
    func auraSectionTitle() -> some View {
        self.font(AuraFont.semi(18))
            .tracking(1.2)
            .textCase(.uppercase)
    }

    func auraLabel(_ size: CGFloat = 12) -> some View {
        self.font(AuraFont.medium(size))
            .tracking(1.4)
            .textCase(.uppercase)
    }

    func auraBody(_ size: CGFloat = 13) -> some View {
        self.font(AuraFont.regular(size))
            .tracking(0.2)
    }

    func auraGlass(corner: CGFloat = 16) -> some View {
        self.padding(16)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(AuraTheme.panelBase)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(AuraTheme.panelStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 8)
    }
}

struct AuraTickRing: View {
    var color: Color = AuraTheme.auraBlue.opacity(0.55)
    var ticks: Int = 60
    var majorEvery: Int = 5

    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0..<ticks, id: \.self) { i in
                    let major = i.isMultiple(of: majorEvery)
                    let len: CGFloat = major ? 8 : 4
                    let w: CGFloat = major ? 1.4 : 0.8
                    Path { p in
                        p.move(to: CGPoint(x: center.x, y: center.y - r))
                        p.addLine(to: CGPoint(x: center.x, y: center.y - r + len))
                    }
                    .stroke(color.opacity(major ? 0.85 : 0.45), lineWidth: w)
                    .rotationEffect(.degrees(Double(i) / Double(ticks) * 360),
                                    anchor: UnitPoint(x: 0.5, y: 0.5))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct AuraStatusDot: View {
    let color: Color
    var pulses: Bool = false
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.9), radius: pulse ? 8 : 3)
            .scaleEffect(pulse ? 1.15 : 1.0)
            .animation(pulses ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true) : .default,
                       value: pulse)
            .onAppear { pulse = pulses }
    }
}

struct AuraDivider: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.clear, AuraTheme.panelStroke, .clear],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(height: 1)
    }
}
