import SwiftUI
import CoreText
import Foundation

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

// Unlock "assemble" choreography: each tile fades in at a slightly random, overlapping
// offset (staggered), then springs into its ordered grid slot.
struct AssembleEffect: ViewModifier {
    var index: Int
    var token: Int
    @State private var faded = false
    @State private var ordered = false
    @State private var scatter: CGSize = .zero
    func body(content: Content) -> some View {
        content
            .opacity(faded ? 1 : 0)
            .scaleEffect(ordered ? 1 : 0.94)
            .offset(ordered ? .zero : scatter)
            .onAppear { run() }
            .onChange(of: token) { _, _ in run() }
    }
    private func run() {
        let a = Double(index) * 2.399963                 // golden-angle spread of directions
        let mag = 28.0 + Double((index * 53) % 42)        // 28..70 px, varied
        scatter = CGSize(width: cos(a) * mag, height: sin(a) * mag - 6)
        faded = false; ordered = false
        withAnimation(.easeOut(duration: 1.1).delay(Double(index) * 0.3)) { faded = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.spring(response: 1.05, dampingFraction: 0.85).delay(Double(index) * 0.2)) { ordered = true }
        }
    }
}
extension View { func assemble(_ index: Int, _ token: Int) -> some View { modifier(AssembleEffect(index: index, token: token)) } }

