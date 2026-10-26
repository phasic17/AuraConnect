import SwiftUI
import Combine
import Foundation

// PROJECT OMICRON — ambient backdrop. Near-black, amber, subtly alive: a drifting glow,
// a twinkling starfield, the occasional comet, and a slow-turning wireframe globe.
// Translucent panels float over it.

private let BG_AMBER = Color(red: 1.0, green: 0.69, blue: 0.28)
private let BG_HOT   = Color(red: 1.0, green: 0.92, blue: 0.72)

private func hash(_ i: Int, _ s: Double) -> Double {
    let v = sin(Double(i) * s) * 43758.5453
    return v - v.rounded(.down)
}

struct AuraBackground: View {
    var energy: Double = 0.6
    @State private var t: Double = 0.0
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    var body: some View {
        let e = max(0.0, min(2.0, energy))
        return Canvas { ctx, size in drawScene(ctx, size, t, e) }
            .ignoresSafeArea()
            .onReceive(timer) { _ in t += 1.0 / 30.0 }
    }
}

private func drawScene(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ e: Double) {
    let W = Double(size.width), H = Double(size.height)
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.012, green: 0.010, blue: 0.018)))
    let gx = W * (0.5 + 0.08 * sin(t * 0.09))
    let gy = H * (0.42 + 0.06 * cos(t * 0.07))
    let glow = GraphicsContext.Shading.radialGradient(
        Gradient(colors: [BG_AMBER.opacity(0.05 + 0.03 * e), .clear]),
        center: CGPoint(x: gx, y: gy), startRadius: 0, endRadius: max(W, H) * 0.7)
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: glow)
    drawStars(ctx, size, t)
    drawGlobe(ctx, size, t, e)
    drawComet(ctx, size, t)
    let vig = GraphicsContext.Shading.radialGradient(
        Gradient(colors: [.clear, .black.opacity(0.55)]),
        center: CGPoint(x: W / 2, y: H / 2), startRadius: min(W, H) * 0.3, endRadius: max(W, H) * 0.75)
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: vig)
}

private func drawStars(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double) {
    let W = Double(size.width), H = Double(size.height)
    for i in 0..<150 {
        let x = hash(i, 12.9898) * W
        let y = hash(i, 78.233) * H
        let twin = 0.5 + 0.5 * sin(t * (0.4 + hash(i, 1.7) * 1.6) + Double(i))
        let baseOp = 0.10 + 0.30 * hash(i, 3.17)
        let op = baseOp * (0.45 + 0.55 * twin)
        let s = 0.6 + 1.4 * hash(i, 5.1)
        let warm = hash(i, 7.7) > 0.82
        let col: Color = warm ? BG_AMBER : .white
        ctx.fill(Path(ellipseIn: CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)), with: .color(col.opacity(op * 0.6)))
    }
}

private func drawComet(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double) {
    let W = Double(size.width), H = Double(size.height)
    let period = 8.0
    let cyc = (t / period).rounded(.down)
    let local = t - cyc * period
    let dur = 1.15
    if local >= dur { return }
    let ci = Int(cyc)
    let p = local / dur
    let start = CGPoint(x: (0.08 + 0.8 * hash(ci, 24.3)) * W, y: (0.04 + 0.22 * hash(ci, 51.7)) * H)
    let ang = Double.pi * 0.16 + hash(ci, 9.1) * 0.34
    let dist = max(W, H) * 0.62
    let fade = sin(p * Double.pi)
    let tailN = 16
    for k in 0..<tailN {
        let tpp = max(p - Double(k) / Double(tailN) * 0.12, 0)
        let tx = start.x + CGFloat(cos(ang) * dist * tpp)
        let ty = start.y + CGFloat(sin(ang) * dist * tpp)
        let op = fade * (1 - Double(k) / Double(tailN)) * 0.5
        let s = 2.2 * (1 - Double(k) / Double(tailN)) + 0.4
        ctx.fill(Path(ellipseIn: CGRect(x: tx - s / 2, y: ty - s / 2, width: s, height: s)), with: .color(BG_HOT.opacity(op)))
    }
    let hx = start.x + CGFloat(cos(ang) * dist * p)
    let hy = start.y + CGFloat(sin(ang) * dist * p)
    ctx.fill(Path(ellipseIn: CGRect(x: hx - 2.4, y: hy - 2.4, width: 4.8, height: 4.8)), with: .color(.white.opacity(fade * 0.9)))
}

private func drawGlobe(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ e: Double) {
    let gx = Double(size.width) * 0.5
    let gy = Double(size.height) * 0.46
    let GR = min(Double(size.width), Double(size.height)) * 0.34
    let rot = t * 0.07
    let base = 0.9 + 0.3 * e
    func proj(_ lat: Double, _ lon: Double) -> (CGPoint, Double) {
        let x3 = cos(lat) * cos(lon + rot)
        let y3 = sin(lat)
        let z3 = cos(lat) * sin(lon + rot)
        return (CGPoint(x: gx + x3 * GR, y: gy - y3 * GR), z3)
    }
    let limb = CGRect(x: gx - GR, y: gy - GR, width: GR * 2, height: GR * 2)
    ctx.fill(Path(ellipseIn: limb), with: .color(Color(red: 0.07, green: 0.04, blue: 0.015).opacity(0.55)))
    ctx.stroke(Path(ellipseIn: limb), with: .color(BG_AMBER.opacity(0.09 * base)), lineWidth: 10)
    ctx.stroke(Path(ellipseIn: limb), with: .color(BG_AMBER.opacity(0.24 * base)), lineWidth: 1.2)
    let lats = [-1.05, -0.52, 0.0, 0.52, 1.05]
    for lat in lats {
        var prev: (CGPoint, Double)? = nil
        var lon = 0.0
        while lon <= 2 * Double.pi + 0.001 {
            let cur = proj(lat, lon)
            if let p = prev {
                let zmid = (p.1 + cur.1) / 2
                var seg = Path(); seg.move(to: p.0); seg.addLine(to: cur.0)
                ctx.stroke(seg, with: .color(BG_AMBER.opacity((zmid > 0 ? 0.32 : 0.09) * base)), lineWidth: zmid > 0 ? 1.0 : 0.7)
            }
            prev = cur; lon += 2 * Double.pi / 64
        }
    }
    var lon0 = 0.0
    while lon0 < Double.pi - 0.001 {
        var prev: (CGPoint, Double)? = nil
        var lat = -Double.pi / 2
        while lat <= Double.pi / 2 + 0.001 {
            let cur = proj(lat, lon0)
            if let p = prev {
                let zmid = (p.1 + cur.1) / 2
                var seg = Path(); seg.move(to: p.0); seg.addLine(to: cur.0)
                ctx.stroke(seg, with: .color(BG_AMBER.opacity((zmid > 0 ? 0.28 : 0.08) * base)), lineWidth: zmid > 0 ? 1.0 : 0.7)
            }
            prev = cur; lat += Double.pi / 48
        }
        lon0 += Double.pi / 6
    }
    let pings: [(Double, Double)] = [(0.7, 0.3), (0.2, 2.1), (-0.4, 4.0), (0.9, 5.2), (-0.1, 1.1)]
    for (i, pg) in pings.enumerated() {
        let (pt, z) = proj(pg.0, pg.1)
        if z > 0 {
            let ph = 0.5 + 0.5 * sin(t * 2 + Double(i) * 1.3)
            let s = 3.0 + 3.5 * ph
            ctx.fill(Path(ellipseIn: CGRect(x: pt.x - s, y: pt.y - s, width: s * 2, height: s * 2)), with: .color(BG_HOT.opacity((0.25 + 0.4 * ph) * base)))
            ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 2, y: pt.y - 2, width: 4, height: 4)), with: .color(.white.opacity(0.9)))
        }
    }
}
