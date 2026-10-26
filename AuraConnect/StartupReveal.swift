import SwiftUI
import Foundation
import AVFoundation
import AppKit

private let CR_AMBER = Color(red: 1.0, green: 0.72, blue: 0.34)
private let CR_OK = Color(red: 0.24, green: 0.90, blue: 0.69)
private func continuumImage() -> Image? {
    if let u = Bundle.main.url(forResource: "continuum_hq", withExtension: "png"), let ns = NSImage(contentsOf: u) { return Image(nsImage: ns) }
    return nil
}

struct StartupReveal: View {
    var onDone: () -> Void
    @State private var started = Date()
    @State private var music: AVAudioPlayer?
    @State private var voice: AVAudioPlayer?
    private let WELCOME = "welcome, let's get started"
    private let PHRASE = "PAUL CHOU   \u{00B7}   ALPHA   ALPHA   BRAVO"

    private func ringP(_ e: Double) -> Double { min(max((e - 0.6) / 8.0, 0), 1) }
    private func welcomeShown(_ e: Double) -> String {
        let L = WELCOME.count; var n = 0
        if e < 1.9 { n = 0 }
        else if e < 1.9 + Double(L) * 0.13 { n = Int((e - 1.9) / 0.13) }
        else if e < 10.0 { n = L }
        else { n = max(0, L - Int((e - 10.0) / 0.13)) }
        return String(WELCOME.prefix(min(max(n, 0), L)))
    }
    private func phraseShown(_ e: Double) -> String {
        let L = PHRASE.count
        if e < 6.3 { return "" }
        return String(PHRASE.prefix(min(L, Int((e - 6.3) / 0.11))))
    }
    private func pct(_ e: Double) -> Int { Int(min(max((e - 10.0) / 3.6, 0), 1) * 100) }
    private func sceneOpacity(_ e: Double) -> Double { min(min(e / 1.2, 1), max(0, (17.1 - e) / 1.7)) }

    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(started)
            GeometryReader { g in
                let D = min(g.size.width, g.size.height) * 0.56
                let cx = g.size.width / 2, cy = g.size.height / 2
                ZStack {
                    Color.black
                    ZStack {
                        if let img = continuumImage() { img.resizable().interpolation(.high).scaledToFit().frame(width: D, height: D) }
                    }
                    .frame(width: g.size.width, height: g.size.height)
                    .mask(Canvas { ctx, size in
                        let c = CGPoint(x: size.width / 2, y: size.height / 2)
                        let bigR = max(size.width, size.height)
                        var p = Path(); p.move(to: c)
                        let steps = max(1, Int(ringP(e) * 360))
                        for i in 0...steps {
                            let frac = Double(i) / 360.0
                            let ang = -Double.pi / 2 - frac * 2 * Double.pi
                            p.addLine(to: CGPoint(x: c.x + CGFloat(cos(ang)) * bigR, y: c.y + CGFloat(sin(ang)) * bigR))
                        }
                        p.closeSubpath(); ctx.fill(p, with: .color(.white))
                    })
                    Group {
                        if e >= 10.0 && e < 13.7 { Text("\(pct(e))%").font(.brand(36)).foregroundStyle(.white.opacity(0.92)) }
                        else if e >= 13.7 {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill").font(.system(size: 30)).foregroundStyle(CR_OK)
                                Text("IDENTITY CONFIRMED").font(.brand(12)).tracking(3).foregroundStyle(CR_OK.opacity(0.9))
                            }.opacity(min((e - 13.7) / 0.7, 1))
                        }
                    }.position(x: cx, y: cy)
                    if e >= 5.9 && e < 10.0 {
                        VStack(spacing: 9) {
                            Text("VOICE AUTHENTICATION").font(.brand(11)).tracking(5).foregroundStyle(CR_AMBER.opacity(0.9))
                            Text(phraseShown(e)).font(.brand(17)).tracking(2).foregroundStyle(.white.opacity(0.95))
                            HStack(spacing: 4) {
                                ForEach(0..<9, id: \.self) { i in
                                    Capsule().fill(CR_AMBER.opacity(0.8)).frame(width: 3, height: 6 + 14 * abs(sin(e * 3 + Double(i) * 0.7)))
                                }
                            }.frame(height: 22).opacity(e < 8.2 ? 1 : 0)
                        }
                        .position(x: cx, y: cy + D / 2 + 64)
                        .opacity(min((e - 5.9) / 0.6, 1) * min((10.0 - e) / 0.7, 1))
                    }
                }
                .overlay(alignment: .topLeading) {
                    let w = welcomeShown(e)
                    if !w.isEmpty {
                        HStack(spacing: 1) {
                            Text(w).font(.brand(19)).foregroundStyle(.white.opacity(0.95))
                            if e < 13.6 { Text("\u{2588}").font(.brand(17)).foregroundStyle(CR_AMBER.opacity(0.4 + 0.5 * sin(e * 5))) }
                        }.padding(.leading, 40).padding(.top, 36)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Text("BUILD " + BUILD_TAG).font(.brand(9)).tracking(2).foregroundStyle(.white.opacity(0.3)).padding(18)
                }
            }
            .opacity(sceneOpacity(e))
        }
        .ignoresSafeArea()
        .onAppear { runSequence() }
    }

    private func play(_ res: String) {
        guard let u = Bundle.main.url(forResource: res, withExtension: "m4a"), let p = try? AVAudioPlayer(contentsOf: u) else { return }
        p.prepareToPlay(); p.play(); voice = p
    }
    private func runSequence() {
        started = Date()
        if let u = Bundle.main.url(forResource: "loading_music", withExtension: "m4a"), let p = try? AVAudioPlayer(contentsOf: u) {
            p.numberOfLoops = -1; p.prepareToPlay(); p.volume = 0; music = p; p.play()
            for i in 0...8 { let vv = Double(i) / 8 * 0.85; DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.10) { self.music?.volume = Float(vv) } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.3) { self.play("aura_auth") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 14.0) { self.play("aura_welcomeback") }
        for i in 0...8 { let vv = 0.85 * (1 - Double(i) / 8); DispatchQueue.main.asyncAfter(deadline: .now() + 15.2 + Double(i) * 0.14) { self.music?.volume = Float(vv) } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 17.1) { self.music?.stop(); onDone() }
    }
}
