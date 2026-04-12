import SwiftUI

@main
struct SwiftiomaticApp: App {
    @State private var model = AppModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Swiftiomatic") {
                    openWindow(id: "about")
                }
            }
        }

        Window("About Swiftiomatic", id: "about") {
            AboutView()
        }
        .windowBackgroundDragBehavior(.enabled)
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
    }
}

