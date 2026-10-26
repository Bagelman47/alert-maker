import SwiftUI

@main
struct alert_makerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)

        // Popup windows opened by openWindow(id: "popup-window", value:)
        WindowGroup(id: "popup-window", for: Int.self) { $value in
            if let idNumber = value {
                PopupView(idNumber: idNumber)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
