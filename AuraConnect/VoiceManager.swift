import SwiftUI
import Combine
import AVFoundation
import Speech

final class VoiceManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var listening = false
    @Published var speaking = false
    @Published var locked = false
    @Published var transcript = ""
    @Published var level: Double = 0

    private let recognizer = SFSpeechRecognizer()
    private let engine = AVAudioEngine()
    private var engineStarted = false
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silence: Timer?
    private var player: AVAudioPlayer?
    private let synth = AVSpeechSynthesizer()
    private var greeted = false
    private var permGranted = false
    private var permDenied = false
    private var permRequested = false
    private let acks = ["aura_ack1", "aura_ack2", "aura_ack3", "aura_ack4"]

    func activate(greet: Bool = true) {
        guard !locked else { return }
        if permDenied { transcript = "(enable Microphone + Speech in System Settings ▸ Privacy)"; return }
        if permGranted { proceed(greet); return }
        if permRequested { return }
        permRequested = true
        ensurePermissions { ok in
            if ok { self.permGranted = true; self.proceed(greet) }
            else { self.permDenied = true; self.transcript = "(enable Microphone + Speech in System Settings ▸ Privacy)" }
        }
    }
    private func proceed(_ greet: Bool) {
        startEngineOnce()
        if greet && !greeted { greeted = true; play("aura_greeting", fallback: "I'm here, Paul. Just talk to me, I'm listening.") }
        else { greeted = true; beginListen() }
    }
    func lock() { locked = true; endListen(); player?.stop(); synth.stopSpeaking(at: .immediate); speaking = false }
    func unlock() { locked = false; activate(greet: false) }

    private func ensurePermissions(_ done: @escaping (Bool) -> Void) {
        func afterMic(_ micOK: Bool) {
            guard micOK else { done(false); return }
            switch SFSpeechRecognizer.authorizationStatus() {
            case .authorized: done(true)
            case .notDetermined: SFSpeechRecognizer.requestAuthorization { s in DispatchQueue.main.async { done(s == .authorized) } }
            default: done(false)
            }
        }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: afterMic(true)
        case .notDetermined: AVCaptureDevice.requestAccess(for: .audio) { g in DispatchQueue.main.async { afterMic(g) } }
        default: afterMic(false)
        }
    }
    private func startEngineOnce() {
        guard !engineStarted else { return }
        let node = engine.inputNode
        let fmt = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            guard let self = self, let r = self.request else { return }
            r.append(buf)
            if let ch = buf.floatChannelData?[0] {
                let nn = Int(buf.frameLength)
                var sum: Float = 0
                if nn > 0 { for i in 0..<nn { sum += abs(ch[i]) } }
                let avg = nn > 0 ? Double(sum) / Double(nn) : 0
                DispatchQueue.main.async { self.level = min(avg * 12, 1) }
            }
        }
        engine.prepare()
        do { try engine.start(); engineStarted = true } catch { transcript = "(microphone unavailable)" }
    }
    private func play(_ resource: String, fallback: String) {
        endListen()
        speaking = true
        if let url = Bundle.main.url(forResource: resource, withExtension: "m4a"), let p = try? AVAudioPlayer(contentsOf: url) {
            p.delegate = self; p.prepareToPlay(); player = p; p.play()
        } else {
            let u = AVSpeechUtterance(string: fallback); u.rate = 0.5
            synth.speak(u)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.finishedSpeaking() }
        }
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { finishedSpeaking() }
    private func finishedSpeaking() { speaking = false; if !locked { beginListen() } }

    private func beginListen() {
        guard !locked, !speaking, engineStarted, request == nil else { return }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req
        listening = true; transcript = ""
        task = recognizer?.recognitionTask(with: req) { res, err in
            DispatchQueue.main.async {
                if let r = res { self.transcript = r.bestTranscription.formattedString; self.armSilence() }
                if err != nil { self.endListen() }
            }
        }
    }
    private func armSilence() {
        silence?.invalidate()
        silence = Timer.scheduledTimer(withTimeInterval: 1.3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            let said = self.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            self.endListen()
            if !said.isEmpty { self.converse(said) } else if !self.locked { self.beginListen() }
        }
    }
    private func endListen() {
        silence?.invalidate(); silence = nil
        request?.endAudio(); task?.cancel(); task = nil; request = nil
        listening = false; level = 0
    }
    private func converse(_ t: String) {
        play(acks.randomElement() ?? "aura_ack1", fallback: "I'm on it.")
    }
}

struct ListeningPill: View {
    @ObservedObject var voice: VoiceManager
    var body: some View {
        let col: Color = voice.speaking ? Aura.ember : (voice.listening ? Aura.ok : Color.white.opacity(0.5))
        let txt: String = voice.speaking ? "AURA SPEAKING" : (voice.listening ? "LISTENING" : "IDLE")
        return HStack(spacing: 8) {
            Circle().fill(col).frame(width: 8, height: 8).opacity(0.45 + 0.55 * (voice.listening ? voice.level : 1))
            Text(txt).font(.brand(11)).tracking(2).foregroundStyle(col)
        }
        .padding(.horizontal, 14).frame(height: 40)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(col.opacity(0.4), lineWidth: 1))
    }
}
struct LockButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) { Image(systemName: "lock.fill").font(.system(size: 14)); Text("LOCK").font(.brand(12)).tracking(3) }
                .foregroundStyle(.white).padding(.horizontal, 18).frame(height: 40)
                .background(Aura.danger.opacity(0.92), in: Capsule())
                .shadow(color: Aura.danger.opacity(0.55), radius: 11)
        }.buttonStyle(.plain)
    }
}
struct SeverButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) { Image(systemName: "bolt.horizontal.circle.fill").font(.system(size: 14)); Text("SEVER LINK").font(.brand(11)).tracking(2) }
                .foregroundStyle(Aura.danger).padding(.horizontal, 14).frame(height: 40)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Aura.danger.opacity(0.5), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}
