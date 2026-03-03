import SwiftUI

struct DevicesView: View {
    @ObservedObject var bt: BluetoothManager

    var body: some View {
        VStack(spacing: 16) {
            topBar
            listPanel
            Spacer()
        }
        .padding(18)
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DEVICES")
                    .auraSectionTitle()
                    .foregroundStyle(.white)

                Text("Radar view. Shows nearby Aura Pucks in Transfer Mode.")
                    .auraBody(12)
                    .foregroundStyle(AuraTheme.textDim)

                Text("To send files: go to TRANSFER, choose a puck, then CONNECT.")
                    .font(AuraFont.regular(11))
                    .tracking(0.6)
                    .foregroundStyle(.white.opacity(0.50))
            }

            Spacer()

            HStack(spacing: 10) {
                Button { bt.startScan() } label: {
                    Label("SCAN", systemImage: "dot.radiowaves.left.and.right")
                        .auraLabel(13)
                }
                .buttonStyle(.borderedProminent)

                Button { bt.stopScan() } label: {
                    Label("STOP", systemImage: "stop.fill")
                        .auraLabel(13)
                }
                .buttonStyle(.bordered)
                .disabled(!bt.isScanning)
            }
        }
        .auraGlass(corner: 18)
    }

    private var listPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if bt.devices.isEmpty {
                Text("NO DEVICES FOUND. PUT THE PUCK INTO TRANSFER MODE AND SCAN.")
                    .font(AuraFont.regular(12))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.65))
            } else {
                ForEach(bt.devices) { d in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(d.name.uppercased())
                                .font(AuraFont.medium(13))
                                .tracking(0.8)
                                .foregroundStyle(.white)

                            Text("RSSI \(d.rssi)")
                                .font(AuraFont.regular(11))
                                .tracking(0.2)
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        Spacer()

                        // Passive hint only
                        Text("VISIBLE")
                            .font(AuraFont.regular(10))
                            .tracking(1.0)
                            .foregroundStyle(AuraTheme.auraCyan.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AuraTheme.auraBlue.opacity(0.18), lineWidth: 1)
                            )
                    }
                    .padding(12)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AuraTheme.auraBlue.opacity(0.14), lineWidth: 1)
                    )
                }
            }
        }
        .auraGlass(corner: 18)
        .frame(maxWidth: 920)
    }
}
