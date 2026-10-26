import SwiftUI
import Combine
import AVFoundation
import Speech

// Always-on conversational voice in Aura's ACTUAL voice (bundled piper renders).
// Requests Speech permission at most once. P1: puck brain streams real replies over BLE.
final class VoiceManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var listening = false
    @Published var speaking = false
    @Published var locked = false
    @Published var transcript = ""
    @Published var level: Double = 0

    private let recognizer = SFSpeechRecognizer()
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silence: Timer?
    private var player: AVAudioPlayer?
    private let synth = AVSpeechSynthesizer()
    private var greeted = false
    private let acks = ["aura_ack1", "aura_ack2", "aura_ack3", "aura_ack4"]

    func activate() {
        guard !locked else { return }
        if !greeted { greeted = true; play("aura_greeting", fallback: "I'm here, Paul. Just talk to me, I'm listening.") }
        else { startListening() }
    }
    func lock() { locked = true; stopListening(); player?.stop(); synth.stopSpeaking(at: .immediate); speaking = false }
    func unlock() { locked = false; activate() }

    private func play(_ resource: String, fallback: String) {
        stopListening()
        speaking = true
        if let url = Bundle.main.url(forResource: resource, withExtension: "m4a"),
           let p = try? AVAudioPlayer(contentsOf: url) {
            p.delegate = self
            player = p
            p.play()
        } else {
            let u = AVSpeechUtterance(string: fallback); u.rate = 0.5
            synth.speak(u)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.finishedSpeaking() }
        }
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { finishedSpeaking() }
    private func finishedSpeaking() {
        speaking = false
        if !locked { startListening() }
    }

    private func startListening() {
        guard !locked, !speaking, !listening else { return }
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            begin()
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { s in
                DispatchQueue.main.async {
                    if s == .authorized { self.begin() } else { self.transcript = "(enable Speech Recognition in System Settings)" }
                }
            }
        default:
            transcript = "(Speech access denied \u{2014} System Settings \u{25B8} Privacy)"
        }
    }
    private func begin() {
        do {
            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req
            let node = engine.inputNode
            let fmt = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in
                req.append(buf)
                if let ch = buf.floatChannelData?[0] {
                    let n = Int(buf.frameLength)
                    var sum: Float = 0
                    if n > 0 { for i in 0..<n { sum += abs(ch[i]) } }
                    let avg = n > 0 ? Double(sum) / Double(n) : 0
                    DispatchQueue.main.async { self.level = min(avg * 12, 1) }
                }
            }
            engine.prepare()
            try engine.start()
            listening = true
            transcript = ""
            task = recognizer?.recognitionTask(with: req) { res, err in
                DispatchQueue.main.async {
                    if let r = res { self.transcript = r.bestTranscription.formattedString; self.armSilence() }
                    if err != nil { self.stopListening() }
                }
            }
        } catch {
            transcript = "(microphone unavailable)"
            listening = false
        }
    }
    private func armSilence() {
        silence?.invalidate()
        silence = Timer.scheduledTimer(withTimeInterval: 1.3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            let said = self.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            self.stopListening()
            if !said.isEmpty { self.converse(said) } else if !self.locked { self.startListening() }
        }
    }
    private func stopListening() {
        silence?.invalidate(); silence = nil
        if engine.isRunning { engine.stop(); engine.inputNode.removeTap(onBus: 0) }
        request?.endAudio(); task?.cancel(); task = nil; request = nil
        listening = false; level = 0
    }
    private func converse(_ t: String) {
        // P0: acknowledge in Aura's actual voice. P1: POST `t` to the puck brain, speak its streamed reply.
        play(acks.randomElement() ?? "aura_ack1", fallback: "I'm on it.")
    }
}

struct ListeningPill: View {
    @ObservedObject var voice: VoiceManager
    var body: some View {
        let col: Color = voice.speaking ? Aura.ember : (voice.listening ? Aura.ok : Color.white.opacity(0.5))
        let txt: String = voice.speaking ? "AURA SPEAKING" : (voice.listening ? "LISTENING" : "IDLE")
        return HStack(spacing: 8) {
            Circle().fill(col).frame(width: 8, height: 8)
                .opacity(0.45 + 0.55 * (voice.listening ? voice.level : 1))
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
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.system(size: 14))
                Text("LOCK").font(.brand(12)).tracking(3)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18).frame(height: 40)
            .background(Aura.danger.opacity(0.92), in: Capsule())
            .shadow(color: Aura.danger.opacity(0.55), radius: 11)
        }
        .buttonStyle(.plain)
    }
}

struct SeverButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.horizontal.circle.fill").font(.system(size: 14))
                Text("SEVER LINK").font(.brand(11)).tracking(2)
            }
            .foregroundStyle(Aura.danger)
            .padding(.horizontal, 14).frame(height: 40)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Aura.danger.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
