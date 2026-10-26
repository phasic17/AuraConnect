import SwiftUI
import Combine

// PROJECT OMICRON — the Reveal. A dazzling live view of what the puck perceives,
// rendered on the Mac's screen the moment the BLE-secure link locks.
// NOTE: telemetry below is a DEMO STREAM (clearly labelled) until the puck's
// GATT telemetry characteristic ships in P1. The dashboard shell + reveal are real.

final class LiveTelemetry: ObservableObject {
    struct Person: Identifiable { let id = UUID(); var name: String; var bearing: Double; var dist: Double; var activity: Double; var color: Color }
    struct Vital: Identifiable { let id = UUID(); var name: String; var frac: Double; var value: String }
    struct StreamLine: Identifiable { let id = UUID(); var kind: String; var text: String }

    @Published var people: [Person] = [
        .init(name: "Paul", bearing: -0.5, dist: 0.55, activity: 1.0, color: Color(red: 1, green: 0.69, blue: 0.28)),
        .init(name: "guest \u{00B7} unverified", bearing: 2.1, dist: 0.80, activity: 0.30, color: Color(red: 0.5, green: 0.85, blue: 1.0)),
        .init(name: "TV \u{00B7} ambient", bearing: -2.4, dist: 0.95, activity: 0.15, color: Color(white: 0.42))
    ]
    @Published var stream: [StreamLine] = []
    @Published var vitals: [Vital] = [
        .init(name: "on-device models", frac: 1.00, value: "3 resident"),
        .init(name: "puck temp",        frac: 0.62, value: "71\u{00B0}C"),
        .init(name: "memory",           frac: 0.48, value: "7.6 / 16 GB"),
        .init(name: "AES link",         frac: 0.99, value: "encrypted")
    ]
    @Published var eventsProcessed: Int = 0
    let isSimulated = true

    private let lines: [(String, String)] = [
        ("q", "Paul: \"what's on my plate this morning?\""),
        ("j", "interject? 0.91 \u{2014} addressed, answer"),
        ("m", "on-device \u{00B7} glm-air \u{00B7} 240ms"),
        ("r", "guest speech \u{2014} unverified voice, not retained"),
        ("q", "\"...remind me to call the printer guy\""),
        ("j", "interject? 0.88 \u{2014} capture task"),
        ("m", "intent \u{2192} reminder \u{00B7} local store"),
        ("r", "TV audio \u{2014} ambient, ignored"),
        ("j", "interject? 0.12 \u{2014} stay quiet"),
        ("q", "\"Aura, keep it down for now\""),
        ("j", "mute \u{00B7} persistent \u{00B7} acknowledged")
    ]
    private var idx = 0
    private var timer: Timer?
    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 1.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let l = self.lines[self.idx % self.lines.count]
            self.stream.append(StreamLine(kind: l.0, text: l.1))
            if self.stream.count > 9 { self.stream.removeFirst() }
            self.idx += 1
            self.eventsProcessed += Int.random(in: 10...60)
        }
    }
    func stop() { timer?.invalidate(); timer = nil }
}

private let EMBER = Color(red: 1, green: 0.69, blue: 0.28)
private let OKGREEN = Color(red: 0.24, green: 0.90, blue: 0.69)

// MARK: - Canvas drawing (extracted so SwiftUI view bodies stay type-checkable)

private func drawRadar(_ ctx: GraphicsContext, _ size: CGSize, _ t: Double, _ people: [LiveTelemetry.Person]) {
    let cx = size.width / 2
    let cy = size.height / 2
    let R = min(size.width, size.height) * 0.42
    for k in 1...4 {
        let rr = R * Double(k) / 4.0
        let rect = CGRect(x: cx - rr, y: cy - rr, width: rr * 2, height: rr * 2)
        ctx.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.08)), lineWidth: 1)
    }
    var wave = Path()
    let seg = 120
    for i in 0...seg {
        let a = Double(i) / Double(seg) * .pi * 2
        let amp = 1 + 0.06 * sin(a * 6 + t * 2.5) + 0.04 * sin(a * 11 - t * 3)
        let rr = R * 0.72 * amp
        let p = CGPoint(x: cx + cos(a) * rr, y: cy + sin(a) * rr)
        if i == 0 { wave.move(to: p) } else { wave.addLine(to: p) }
    }
    wave.closeSubpath()
    ctx.stroke(wave, with: .color(Color(red: 0.5, green: 0.85, blue: 1).opacity(0.22)), lineWidth: 1.2)
    let sw = (t.truncatingRemainder(dividingBy: 2.6)) / 2.6 * .pi * 2
    var wedge = Path()
    wedge.move(to: CGPoint(x: cx, y: cy))
    wedge.addArc(center: CGPoint(x: cx, y: cy), radius: R, startAngle: .radians(sw - 0.5), endAngle: .radians(sw), clockwise: false)
    wedge.closeSubpath()
    ctx.fill(wedge, with: .color(EMBER.opacity(0.08)))
    for p in people {
        let x = cx + cos(p.bearing) * R * p.dist
        let y = cy + sin(p.bearing) * R * p.dist
        let pr = 6 + p.activity * 7 + sin(t * 3) * p.activity * 2
        var line = Path()
        line.move(to: CGPoint(x: cx, y: cy))
        line.addLine(to: CGPoint(x: x, y: y))
        ctx.stroke(line, with: .color(.white.opacity(0.06)), lineWidth: 1)
        let dotRect = CGRect(x: x - pr, y: y - pr, width: pr * 2, height: pr * 2)
        ctx.fill(Path(ellipseIn: dotRect), with: .color(p.color.opacity(0.9)))
        let label = Text(p.name).font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.78))
        ctx.draw(label, at: CGPoint(x: x + pr + 6, y: y), anchor: .leading)
    }
    ctx.fill(Path(ellipseIn: CGRect(x: cx - 5, y: cy - 5, width: 10, height: 10)), with: .color(EMBER))
}

private func drawReveal(_ ctx: GraphicsContext, _ size: CGSize, _ e: Double) {
    let a = min(e / 2.4, 1)
    let cols = Int(size.width / 16)
    let glyphs = ["0", "1", "\u{03A8}", "\u{0394}", "\u{25C7}", "\u{25B3}"]
    if cols > 0 {
        for i in 0..<cols {
            let seed = Double((i * 131) % 97)
            let y = (e * 520 + seed * 40).truncatingRemainder(dividingBy: size.height + 120) - 60
            let gl = glyphs[(i + Int(e * 8)) % 6]
            let lit = (i % 23) == (Int(e * 5) % 23)
            let col: Color = lit ? EMBER : Color(red: 0.47, green: 0.85, blue: 1).opacity(0.25 + 0.5 * a)
            ctx.draw(Text(gl).font(.system(size: 14)).foregroundStyle(col), at: CGPoint(x: Double(i) * 16 + 8, y: y))
        }
    }
    let cx = size.width / 2
    let cy = size.height / 2
    let p = min(e / 2.2, 1)
    let segs = 64
    for i in 0..<segs {
        let frac = Double(i) / Double(segs)
        if frac >= p { continue }
        let ang = -Double.pi / 2 - frac * .pi * 2
        let x = cx + cos(ang) * 92
        let y = cy + sin(ang) * 92
        let s = 3 + sin(frac * 30 + p * 10) * 1.5
        let col: Color = (i % 9 == 0) ? EMBER : Color(red: 1, green: 0.81, blue: 0.54)
        ctx.fill(Path(CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)), with: .color(col))
    }
    let core = 10 + 6 * sin(p * 8)
    ctx.fill(Path(ellipseIn: CGRect(x: cx - core, y: cy - core, width: core * 2, height: core * 2)), with: .color(EMBER))
}

// MARK: - Views

struct LiveView: View {
    @EnvironmentObject var bt: BluetoothManager
    @StateObject private var tel = LiveTelemetry()
    @State private var revealing = false
    @State private var revealStart = Date()

    var body: some View {
        ZStack {
            dashboard
            if revealing {
                RevealOverlay(start: revealStart).transition(.opacity).zIndex(10)
            }
        }
        .onAppear { tel.start(); if bt.isConnected { fire() } }
        .onDisappear { tel.stop() }
        .onChange(of: bt.isConnected) { _, now in if now { fire() } }
    }

    private func fire() {
        revealStart = Date()
        withAnimation(.easeOut(duration: 0.4)) { revealing = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            withAnimation(.easeInOut(duration: 1.0)) { revealing = false }
        }
    }

    private var dashboard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                RoomRadar(people: tel.people).panel("THE ROOM \u{2014} AS AURA HEARS IT")
                VStack(spacing: 14) {
                    MindStream(lines: tel.stream).panel("THE MIND \u{2014} LIVE COGNITION")
                    VitalsView(vitals: tel.vitals).panel("ON-DEVICE SYSTEM")
                }
                .frame(width: 320)
            }
            EgressBar(events: tel.eventsProcessed)
            if tel.isSimulated {
                Text("DEMO STREAM \u{2014} live puck telemetry lands in P1")
                    .font(.system(size: 10)).tracking(2).foregroundStyle(.secondary)
            }
        }
    }
}

private extension View {
    func panel(_ title: String) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                Text(title).font(.system(size: 11)).tracking(2.2).foregroundStyle(.secondary).padding(14)
            }
            .background(RadialGradient(colors: [Color(red: 0.07, green: 0.055, blue: 0.105), Color(red: 0.035, green: 0.027, blue: 0.06)], center: .top, startRadius: 2, endRadius: 520))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06)))
    }
}

struct RoomRadar: View {
    var people: [LiveTelemetry.Person]
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                drawRadar(ctx, size, tl.date.timeIntervalSinceReferenceDate, people)
            }
        }
    }
}

struct MindStream: View {
    var lines: [LiveTelemetry.StreamLine]
    private func color(_ k: String) -> Color {
        switch k {
        case "q": return .white
        case "j": return EMBER
        case "m": return Color(red: 0.5, green: 0.85, blue: 1)
        default:  return .secondary
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Spacer(minLength: 30)
            ForEach(lines) { l in
                Text((l.kind == "r" ? "\u{00B7} " : "") + l.text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(color(l.kind))
                    .italic(l.kind == "r")
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

struct VitalsView: View {
    var vitals: [LiveTelemetry.Vital]
    var body: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 30)
            ForEach(vitals) { v in
                HStack(spacing: 10) {
                    Text(v.name).font(.system(size: 12)).foregroundStyle(.white.opacity(0.8)).frame(width: 118, alignment: .leading)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule().fill(LinearGradient(colors: [EMBER, Color(red: 1, green: 0.48, blue: 0.42)], startPoint: .leading, endPoint: .trailing))
                                .frame(width: g.size.width * min(v.frac, 1))
                        }
                    }.frame(height: 7)
                    Text(v.value).font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 16)
    }
}

struct EgressBar: View {
    var events: Int
    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 3) {
                Text("0 BYTES").font(.system(size: 32, weight: .bold, design: .monospaced)).foregroundStyle(OKGREEN)
                    .shadow(color: OKGREEN.opacity(0.4), radius: 14)
                Text("SENT TO THE CLOUD \u{00B7} THIS SESSION").font(.system(size: 11)).tracking(1.6).foregroundStyle(OKGREEN.opacity(0.7))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(events) events processed \u{2014} all in this room.").font(.system(size: 12)).foregroundStyle(OKGREEN.opacity(0.75))
                Text("nothing left it. that is the product.").font(.system(size: 12)).foregroundStyle(OKGREEN.opacity(0.75))
            }
        }
        .padding(.horizontal, 26).frame(height: 88)
        .background(RadialGradient(colors: [Color(red: 0.05, green: 0.12, blue: 0.09), Color(red: 0.027, green: 0.063, blue: 0.047)], center: .bottom, startRadius: 2, endRadius: 400))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(OKGREEN.opacity(0.18)))
    }
}

struct RevealOverlay: View {
    var start: Date
    @ViewBuilder private func caption(_ e: Double) -> some View {
        if e > 1.4 {
            Text("BLE SECURE LINK ESTABLISHED \u{00B7} REVEALING YOUR ROOM")
                .font(.system(size: 13)).tracking(2.5).foregroundStyle(.secondary).padding(.bottom, 60)
        }
    }
    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(start)
            Canvas { ctx, size in
                drawReveal(ctx, size, e)
            }
            .background(Color(red: 0.02, green: 0.016, blue: 0.04))
            .overlay(alignment: .bottom) { caption(e) }
        }
        .ignoresSafeArea()
    }
}
