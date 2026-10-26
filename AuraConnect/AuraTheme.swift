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


// Unlock choreography: each tile PIXELATES in (block-dissolve), one at a time and slow,
// at a random overlapping offset; once the last has materialized, they order into the grid.
struct PixelMask: View {
    var start: Date?
    private func cellHash(_ c: Int, _ r: Int) -> Double {
        let v = sin(Double(c) * 12.9898 + Double(r) * 78.233) * 43758.5453
        return v - v.rounded(.down)
    }
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                guard let s = start else { return }
                let p = min(max(tl.date.timeIntervalSince(s) / 1.6, 0), 1)
                if p >= 1 { return }
                let cell = 15.0
                let cols = Int(ceil(size.width / cell))
                let rows = Int(ceil(size.height / cell))
                for r in 0..<rows {
                    for c in 0..<cols {
                        let h = cellHash(c, r)
                        if h > p {
                            let aedge = min((h - p) / 0.09, 1)
                            ctx.fill(Path(CGRect(x: Double(c) * cell, y: Double(r) * cell, width: cell + 0.7, height: cell + 0.7)),
                                     with: .color(Color(red: 0.02, green: 0.016, blue: 0.03).opacity(0.96 * aedge)))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct AssembleEffect: ViewModifier {
    var index: Int
    var count: Int
    var token: Int
    @State private var started: Date? = nil
    @State private var ordered = false
    @State private var scatter: CGSize = .zero
    func body(content: Content) -> some View {
        content
            .overlay(PixelMask(start: started))
            .opacity(started == nil ? 0 : 1)
            .offset(ordered ? .zero : scatter)
            .onAppear { run() }
            .onChange(of: token) { _, _ in run() }
    }
    private func run() {
        let dur = 1.7
        let a = Double(index) * 2.399963
        let mag = 55.0 + Double((index * 53) % 70)
        scatter = CGSize(width: cos(a) * mag, height: sin(a) * mag - 10)
        started = nil; ordered = false
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * dur) { started = Date() }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(count) * dur + 0.6) {
            withAnimation(.spring(response: 1.15, dampingFraction: 0.86)) { ordered = true }
        }
    }
}
extension View { func assemble(_ index: Int, _ count: Int, _ token: Int) -> some View { modifier(AssembleEffect(index: index, count: count, token: token)) } }
