import SwiftUI

private func drawVault(_ ctx: GraphicsContext, _ size: CGSize, _ p: Double, _ t: Double) {
    let cx = size.width / 2
    let cy = size.height / 2
    let R = min(size.width, size.height) * 0.34
    let blades = 8
    for b in 0..<blades {
        let a = Double(b) / Double(blades) * 2 * .pi
        let a2 = a + 2 * .pi / Double(blades)
        let inner = R * (0.12 + 0.88 * (1 - p))
        var path = Path()
        path.move(to: CGPoint(x: cx + cos(a) * R, y: cy + sin(a) * R))
        path.addLine(to: CGPoint(x: cx + cos(a2) * R, y: cy + sin(a2) * R))
        path.addLine(to: CGPoint(x: cx + cos(a2) * inner, y: cy + sin(a2) * inner))
        path.addLine(to: CGPoint(x: cx + cos(a) * inner, y: cy + sin(a) * inner))
        path.closeSubpath()
        ctx.fill(path, with: .color(Color(red: 0.10, green: 0.08, blue: 0.05)))
        ctx.stroke(path, with: .color(Aura.ember.opacity(0.4)), lineWidth: 1)
    }
    for k in 0..<3 {
        let rr = R * (0.52 + Double(k) * 0.16)
        let rect = CGRect(x: cx - rr, y: cy - rr, width: rr * 2, height: rr * 2)
        ctx.stroke(Path(ellipseIn: rect), with: .color(Aura.ember.opacity(0.3)),
                   style: StrokeStyle(lineWidth: 2, dash: [6, 10], dashPhase: t * 20))
    }
    let lock = 10 + 8 * (1 - p)
    let col: Color = p > 0.9 ? Aura.danger : Aura.ember
    ctx.fill(Path(ellipseIn: CGRect(x: cx - lock, y: cy - lock, width: lock * 2, height: lock * 2)), with: .color(col))
}

struct DisconnectVault: View {
    var onClosed: () -> Void
    @State private var start = Date()
    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(start)
            let p = min(e / 2.6, 1)
            ZStack {
                Color.black
                Canvas { ctx, size in drawVault(ctx, size, p, e) }
                VStack(spacing: 10) {
                    Spacer()
                    if e > 1.6 {
                        Text("LINK SEVERED").font(.brand(16)).tracking(6).foregroundStyle(Aura.danger)
                    }
                    if e > 2.0 {
                        Text("0 BYTES LEFT THE ROOM").font(.brand(11)).tracking(3).foregroundStyle(Aura.ok.opacity(0.85)).padding(.bottom, 72)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { start = Date(); DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { onClosed() } }
    }
}
