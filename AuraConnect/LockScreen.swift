import SwiftUI
import Foundation

private func drawLock(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double) {
    let cx = Double(size.width) / 2
    let cy = Double(size.height) / 2
    for k in 0..<5 {
        let r = 72.0 + Double(k) * 46
        let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
        let col: Color = k % 2 == 0 ? Aura.danger : Aura.ember
        let phase = (k % 2 == 0) ? t * 6 : t * -5
        ctx.stroke(Path(ellipseIn: rect), with: .color(col.opacity(0.16)),
                   style: StrokeStyle(lineWidth: 1.5, dash: [8, 16], dashPhase: phase))
    }
    let pr = 54.0 + 6 * sin(t * 0.7)
    ctx.stroke(Path(ellipseIn: CGRect(x: cx - pr, y: cy - pr, width: pr * 2, height: pr * 2)),
               with: .color(Aura.danger.opacity(0.45)), lineWidth: 2)
    let sw = (t / 14.0 - (t / 14.0).rounded(.down)) * Double.pi * 2
    var wedge = Path()
    wedge.move(to: CGPoint(x: cx, y: cy))
    wedge.addArc(center: CGPoint(x: cx, y: cy), radius: 300, startAngle: .radians(sw - 0.22), endAngle: .radians(sw), clockwise: false)
    wedge.closeSubpath()
    ctx.fill(wedge, with: .color(Aura.danger.opacity(0.05)))
    for i in 0..<48 {
        let a = Double(i) / 48 * Double.pi * 2
        let r0 = 250.0, r1 = 262.0
        var p = Path()
        p.move(to: CGPoint(x: cx + cos(a) * r0, y: cy + sin(a) * r0))
        p.addLine(to: CGPoint(x: cx + cos(a) * r1, y: cy + sin(a) * r1))
        ctx.stroke(p, with: .color(Aura.ember.opacity(0.18)), lineWidth: 1)
    }
}

struct LockScreen: View {
    var onUnlock: () -> Void
    @State private var start = Date()
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(start)
            ZStack {
                Color(red: 0.04, green: 0.012, blue: 0.02).ignoresSafeArea()
                Canvas { ctx, size in drawLock(ctx, size, t) }
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill").font(.system(size: 44)).foregroundStyle(Aura.danger)
                        .shadow(color: Aura.danger.opacity(0.6), radius: 22)
                    Text("SECURED").font(.brand(30)).tracking(10).foregroundStyle(.white)
                    Text("MICROPHONE & SPEAKER OFF \u{00B7} NOTHING IS HEARD")
                        .font(.brand(12)).tracking(3).foregroundStyle(Aura.ember.opacity(0.75))
                    Button(action: onUnlock) {
                        HStack(spacing: 8) { Image(systemName: "lock.open.fill"); Text("UNLOCK & RESUME").font(.brand(13)).tracking(3) }
                            .foregroundStyle(.white).padding(.horizontal, 26).frame(height: 48)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Aura.danger.opacity(0.7), lineWidth: 1.5))
                    }.buttonStyle(.plain).padding(.top, 12)
                }
            }
        }
        .ignoresSafeArea().transition(.opacity)
    }
}
