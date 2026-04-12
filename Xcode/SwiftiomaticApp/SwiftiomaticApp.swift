import AppKit
import SwiftUI

@main
struct SwiftiomaticApp: App {
    @Environment(\.openWindow) private var openWindow

    init() {
        // Show hidden files in all open panels so `.swiftiomatic.yaml` is visible
        NotificationCenter.default.addObserver(
            forName: NSWindow.didUpdateNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let panel = notification.object as? NSOpenPanel, !panel.showsHiddenFiles {
                panel.showsHiddenFiles = true
            }
        }
    }

    var body: some Scene {
        DocumentGroup(newDocument: { SwiftiomaticDocument() }) { file in
            ContentView(document: file.document)
                .task {
                    // Replace the default filename title with the parent folder name
                    if let url = file.fileURL {
                        let folderName = url.deletingLastPathComponent().lastPathComponent
                        NSApp.keyWindow?.title = folderName
                    }
                }
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

