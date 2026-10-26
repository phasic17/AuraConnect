import SwiftUI
import Foundation
import AVFoundation

private let CR_AMBER = Color(red: 1.0, green: 0.72, blue: 0.34)
private let CR_HOT   = Color(red: 1.0, green: 0.95, blue: 0.80)

private func drawContinuum(_ ctx: GraphicsContext, _ size: CGSize, _ prog: Double) {
    let cx = Double(size.width) / 2
    let cy = Double(size.height) / 2
    let R = min(Double(size.width), Double(size.height)) * 0.22
    let N = 104
    ctx.stroke(Path(ellipseIn: CGRect(x: cx - R, y: cy - R, width: R * 2, height: R * 2)),
               with: .color(CR_AMBER.opacity(0.06)), lineWidth: 1)
    for i in 0..<N {
        let frac = Double(i) / Double(N)
        if frac > prog { continue }
        let ang = -Double.pi / 2 - frac * 2 * Double.pi
        let x = cx + cos(ang) * R
        let y = cy + sin(ang) * R
        let lead = max(0, 1 - (prog - frac) / 0.05)
        let base = 0.5 + 0.5 * lead
        let hs = 6.0 + 7.0 * lead
        ctx.fill(Path(ellipseIn: CGRect(x: x - hs, y: y - hs, width: hs * 2, height: hs * 2)),
                 with: .color(CR_AMBER.opacity(0.05 + 0.14 * lead)))
        let s = 6.5
        let col: Color = lead > 0.4 ? CR_HOT : CR_AMBER
        ctx.fill(Path(roundedRect: CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s), cornerRadius: 1.4),
                 with: .color(col.opacity(base)))
    }
}

struct StartupReveal: View {
    var onDone: () -> Void
    @State private var started = Date()
    @State private var player: AVAudioPlayer?
    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(started)
            let prog = min(max((e - 0.8) / 11.8, 0), 1)
            ZStack {
                Color.black
                Canvas { ctx, size in drawContinuum(ctx, size, prog) }
                VStack(spacing: 8) {
                    Text("\(Int(prog * 100))%").font(.brand(36)).foregroundStyle(.white)
                    Text("LOADING").font(.brand(11)).tracking(6).foregroundStyle(CR_AMBER.opacity(0.8))
                    Text("ESTABLISHING SECURE LINK").font(.brand(9)).tracking(3).foregroundStyle(.white.opacity(0.32))
                }
                if e > 12.6 {
                    VStack {
                        Spacer()
                        Text("A U R A   C O N N E C T").font(.brand(14)).tracking(4)
                            .foregroundStyle(.white.opacity(min((e - 12.6) / 1.2, 1) * 0.9))
                            .padding(.bottom, 90)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            started = Date()
            if let u = Bundle.main.url(forResource: "loading_music", withExtension: "m4a"),
               let p = try? AVAudioPlayer(contentsOf: u) {
                p.volume = 0; player = p; p.play()
                for i in 0...10 { let vv = Double(i) / 10 * 0.85; DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) { self.player?.volume = Float(vv) } }
            }
            for i in 0...10 { let vv = 0.85 * (1 - Double(i) / 10); DispatchQueue.main.asyncAfter(deadline: .now() + 13.4 + Double(i) * 0.14) { self.player?.volume = Float(vv) } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { self.player?.stop(); onDone() }
        }
    }
}
