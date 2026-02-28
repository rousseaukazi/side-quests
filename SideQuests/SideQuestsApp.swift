import SwiftUI

@main
struct SideQuestsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window — menu bar only app (LSUIElement = YES in Info.plist)
        Settings {
            EmptyView()
        }
    }
}
