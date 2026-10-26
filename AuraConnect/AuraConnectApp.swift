import SwiftUI

@main
struct AuraConnectApp: App {
    @StateObject private var bt = BluetoothManager()

    var body: some Scene {
        WindowGroup("AuraConnect") {
            ContentView()
                .environmentObject(bt)
                .frame(minWidth: 980, minHeight: 640)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
