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

    private func ringP(_ e: Double) -> Double { min(max((e - 1.2) / 16.0, 0), 1) }
    private func welcomeShown(_ e: Double) -> String {
        let L = WELCOME.count; var n = 0
        if e < 4.0 { n = 0 }
        else if e < 4.0 + Double(L) * 0.26 { n = Int((e - 4.0) / 0.26) }
        else if e < 21.0 { n = L }
        else { n = max(0, L - Int((e - 21.0) / 0.26)) }
        return String(WELCOME.prefix(min(max(n, 0), L)))
    }
    private func phraseShown(_ e: Double) -> String {
        let L = PHRASE.count
        if e < 13.5 { return "" }
        let n = min(L, Int((e - 13.5) / 0.22))
        return String(PHRASE.prefix(n))
    }
    private func pct(_ e: Double) -> Int { Int(min(max((e - 21.0) / 7.0, 0), 1) * 100) }
    private func sceneOpacity(_ e: Double) -> Double { min(min(e / 2.6, 1), max(0, (36.0 - e) / 3.6)) }

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
                    // center: % then confirmation
                    Group {
                        if e >= 21.0 && e < 29.0 { Text("\(pct(e))%").font(.brand(36)).foregroundStyle(.white.opacity(0.92)) }
                        else if e >= 29.0 {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill").font(.system(size: 30)).foregroundStyle(CR_OK)
                                Text("IDENTITY CONFIRMED").font(.brand(12)).tracking(3).foregroundStyle(CR_OK.opacity(0.9))
                            }.opacity(min((e - 29.0) / 1.2, 1))
                        }
                    }.position(x: cx, y: cy)
                    // voice-auth: BELOW the ring, printed as Aura speaks
                    if e >= 12.5 && e < 21.0 {
                        VStack(spacing: 9) {
                            Text("VOICE AUTHENTICATION").font(.brand(11)).tracking(5).foregroundStyle(CR_AMBER.opacity(0.9))
                            Text(phraseShown(e)).font(.brand(17)).tracking(2).foregroundStyle(.white.opacity(0.95))
                            HStack(spacing: 4) {
                                ForEach(0..<9, id: \.self) { i in
                                    Capsule().fill(CR_AMBER.opacity(0.8)).frame(width: 3, height: 6 + 14 * abs(sin(e * 3 + Double(i) * 0.7)))
                                }
                            }.frame(height: 22).opacity(e < 17.0 ? 1 : 0)
                        }
                        .position(x: cx, y: cy + D / 2 + 64)
                        .opacity(min((e - 12.5) / 1.0, 1) * min((21.0 - e) / 1.2, 1))
                    }
                }
                .overlay(alignment: .topLeading) {
                    let w = welcomeShown(e)
                    if !w.isEmpty {
                        HStack(spacing: 1) {
                            Text(w).font(.brand(19)).foregroundStyle(.white.opacity(0.95))
                            if e < 28.5 { Text("\u{2588}").font(.brand(17)).foregroundStyle(CR_AMBER.opacity(0.4 + 0.5 * sin(e * 5))) }
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
            for i in 0...10 { let vv = Double(i) / 10 * 0.8; DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) { self.music?.volume = Float(vv) } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 13.3) { self.play("aura_auth") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 29.5) { self.play("aura_welcomeback") }
        for i in 0...10 { let vv = 0.8 * (1 - Double(i) / 10); DispatchQueue.main.asyncAfter(deadline: .now() + 33.0 + Double(i) * 0.26) { self.music?.volume = Float(vv) } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 36.0) { self.music?.stop(); onDone() }
    }
}
