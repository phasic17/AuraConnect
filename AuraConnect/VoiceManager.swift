import SwiftUI
import Combine
import AVFoundation
import Speech

final class VoiceManager: NSObject, ObservableObject {
    @Published var listening = false
    @Published var transcript = ""
    @Published var spoken = ""
    private let synth = AVSpeechSynthesizer()
    private let recognizer = SFSpeechRecognizer()
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func speak(_ s: String) {
        spoken = s
        let u = AVSpeechUtterance(string: s)
        u.rate = 0.5
        synth.speak(u)
    }
    func toggle() { listening ? stop() : start() }
    func start() {
        SFSpeechRecognizer.requestAuthorization { auth in
            DispatchQueue.main.async {
                guard auth == .authorized else { self.transcript = "(speech not authorized)"; return }
                self.beginListen()
            }
        }
    }
    private func beginListen() {
        do {
            let req = SFSpeechAudioBufferRecognitionRequest()
            request = req
            let node = engine.inputNode
            let fmt = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in req.append(buf) }
            engine.prepare()
            try engine.start()
            listening = true
            task = recognizer?.recognitionTask(with: req) { res, err in
                if let r = res {
                    self.transcript = r.bestTranscription.formattedString
                    if r.isFinal { self.converse(self.transcript) }
                }
                if err != nil { self.stop() }
            }
        } catch {
            transcript = "(mic error)"
            listening = false
        }
    }
    func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        listening = false
    }
    private func converse(_ t: String) {
        let reply = t.isEmpty ? "I didn't catch that." : "Heard you: \(t). I'm on it."
        speak(reply)
        stop()
    }
}

struct MicButton: View {
    @ObservedObject var voice: VoiceManager
    var body: some View {
        Button { voice.toggle() } label: {
            Image(systemName: voice.listening ? "waveform.circle.fill" : "mic.fill")
                .font(.system(size: 16))
                .foregroundStyle(voice.listening ? Aura.ok : Aura.ember)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke((voice.listening ? Aura.ok : Aura.ember).opacity(0.55), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help("Talk to Aura")
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
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Aura.danger.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
