import SwiftUI

struct LogsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("LOGS")
                .auraSectionTitle()
                .foregroundStyle(.white)

            Text("Placeholder: transfers, updates, verification results, errors.")
                .auraBody(12)
                .foregroundStyle(AuraTheme.textDim)

            Spacer()
        }
        .padding(18)
    }
}

