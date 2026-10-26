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


private func thashT(_ i: Int, _ s: Double) -> Double { let v = sin(Double(i) * s) * 43758.5453; return v - v.rounded(.down) }

struct PixelMask: View {
    var start: Date?
    var dur: Double = 2.6
    private func cellHash(_ c: Int, _ r: Int) -> Double {
        let v = sin(Double(c) * 12.9898 + Double(r) * 78.233) * 43758.5453
        return v - v.rounded(.down)
    }
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                guard let s = start else { return }
                let p = min(max(tl.date.timeIntervalSince(s) / dur, 0), 1)
                if p >= 1 { return }
                let cell = 15.0
                let cols = Int(ceil(size.width / cell)), rows = Int(ceil(size.height / cell))
                for r in 0..<rows {
                    for c in 0..<cols {
                        let h = cellHash(c, r)
                        if h > p {
                            let aedge = min((h - p) / 0.08, 1)
                            ctx.fill(Path(CGRect(x: Double(c) * cell, y: Double(r) * cell, width: cell + 0.7, height: cell + 0.7)),
                                     with: .color(Color(red: 0.03, green: 0.025, blue: 0.045).opacity(0.97 * aedge)))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// Each tile is hidden until its turn, then PIXELATES in (slow) at a central, overlapping
// offset; once the last tile has materialized they all spring out to their grid slots.
struct AssembleEffect: ViewModifier {
    var index: Int
    var count: Int
    var pull: CGSize
    var token: Int
    private let dur = 2.6
    @State private var started: Date? = nil
    @State private var ordered = false
    @State private var jitter: CGSize = .zero
    func body(content: Content) -> some View {
        content
            .overlay(PixelMask(start: started, dur: dur))
            .opacity(started == nil ? 0 : 1)
            .offset(ordered ? .zero : CGSize(width: pull.width + jitter.width, height: pull.height + jitter.height))
            .zIndex(Double(index))
            .onAppear { run() }
            .onChange(of: token) { _, _ in run() }
    }
    private func run() {
        jitter = CGSize(width: (thashT(index, 3.1) - 0.5) * 70, height: (thashT(index, 7.7) - 0.5) * 26)
        started = nil; ordered = false
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * dur) { started = Date() }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(count) * dur + 0.5) {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.86)) { ordered = true }
        }
    }
}
extension View {
    func assemble(_ index: Int, _ count: Int, _ pullX: Double, _ pullY: Double, _ token: Int) -> some View {
        modifier(AssembleEffect(index: index, count: count, pull: CGSize(width: pullX, height: pullY), token: token))
    }
}
