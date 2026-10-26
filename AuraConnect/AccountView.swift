import SwiftUI

struct AccountView: View {
    @State private var displayName: String = "Paul Chou"
    @State private var email: String = "plchou@gmail.com"
    @State private var orgName: String = "LedgerAI"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            profilePanel
            keysPanel
            Spacer()
        }
        .padding(.top, 6)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Account")
                .auraSectionTitle()
                .foregroundStyle(AuraTheme.textPrimary)
            Text("Identity and signing keys associated with this puck pairing.")
                .auraBody(12)
                .foregroundStyle(AuraTheme.textDim)
        }
    }

    private var profilePanel: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                Circle().stroke(AuraTheme.auraBlue.opacity(0.5), lineWidth: 1.4)
                    .frame(width: 78, height: 78)
                AuraTickRing(color: AuraTheme.auraBlue.opacity(0.45), ticks: 60, majorEvery: 5)
                    .frame(width: 78, height: 78)
                Circle().fill(AuraTheme.auraBlue.opacity(0.18))
                    .frame(width: 56, height: 56)
                Text(initials)
                    .font(AuraFont.semi(20))
                    .foregroundStyle(AuraTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Field(label: "Display Name", text: $displayName)
                Field(label: "Email",        text: $email)
                Field(label: "Organization", text: $orgName)
            }
            Spacer()
        }
        .auraGlass(corner: 18)
    }

    private var keysPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Signing keys")
                .auraLabel(11)
                .foregroundStyle(AuraTheme.textDim)

            KeyRow(label: "Device key",  fingerprint: "5F 9C 12 8A 4D … 71 E2", lastUsed: "moments ago")
            KeyRow(label: "Account key", fingerprint: "B7 31 9F 02 6E … 88 4C", lastUsed: "yesterday")
        }
        .auraGlass(corner: 18)
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        return parts.prefix(2).map { String($0.first ?? Character("")) }.joined()
    }
}

private struct Field: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(AuraFont.medium(10))
                .tracking(1.4)
                .foregroundStyle(AuraTheme.textFaint)
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(AuraFont.medium(13))
                .foregroundStyle(AuraTheme.textPrimary)
        }
        .frame(minWidth: 260, alignment: .leading)
    }
}

private struct KeyRow: View {
    let label: String
    let fingerprint: String
    let lastUsed: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .foregroundStyle(AuraTheme.auraBlue)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .auraLabel(11)
                    .foregroundStyle(AuraTheme.textPrimary)
                Text(fingerprint)
                    .font(AuraFont.mono(11))
                    .foregroundStyle(AuraTheme.textDim)
            }
            Spacer()
            Text(lastUsed)
                .auraBody(11)
                .foregroundStyle(AuraTheme.textFaint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AuraTheme.panelStroke, lineWidth: 1)
        )
    }
}
