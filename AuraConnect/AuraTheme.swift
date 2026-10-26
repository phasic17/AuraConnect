import SwiftUI
import CoreText

enum Aura {
    static let bg     = Color(red: 0.02, green: 0.02, blue: 0.045)
    static let ember  = Color(red: 1.0,  green: 0.69, blue: 0.28)   // PRIMARY brand accent
    static let amberLo = Color(red: 1.0, green: 0.48, blue: 0.22)
    static let cyan   = Color(red: 0.42, green: 0.85, blue: 1.0)    // secondary / data
    static let ok     = Color(red: 0.24, green: 0.90, blue: 0.69)
    static let danger = Color(red: 1.0,  green: 0.40, blue: 0.40)
}

extension Font {
    static func brand(_ s: CGFloat) -> Font { .custom("ChakraPetch-SemiBold", size: s) }
    static func brandLight(_ s: CGFloat) -> Font { .custom("ChakraPetch-Light", size: s) }
}

enum AuraFonts {
    static func register() {
        for n in ["ChakraPetch-SemiBold", "ChakraPetch-Light"] {
            if let url = Bundle.main.url(forResource: n, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}

struct CornerTicks: View {
    var accent: Color = Aura.ember
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let L: CGFloat = 13
            Path { p in
                p.move(to: CGPoint(x: 0, y: L)); p.addLine(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: L, y: 0))
                p.move(to: CGPoint(x: w - L, y: 0)); p.addLine(to: CGPoint(x: w, y: 0)); p.addLine(to: CGPoint(x: w, y: L))
                p.move(to: CGPoint(x: 0, y: h - L)); p.addLine(to: CGPoint(x: 0, y: h)); p.addLine(to: CGPoint(x: L, y: h))
                p.move(to: CGPoint(x: w - L, y: h)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: w, y: h - L))
            }
            .stroke(accent.opacity(0.6), lineWidth: 1.5)
        }
        .allowsHitTesting(false)
    }
}

struct GlassTile: ViewModifier {
    var accent: Color = Aura.ember
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(accent.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.24), lineWidth: 1))
            .overlay(CornerTicks(accent: accent))
            .shadow(color: accent.opacity(0.14), radius: 16)
    }
}
extension View { func glass(_ a: Color = Aura.ember) -> some View { modifier(GlassTile(accent: a)) } }
