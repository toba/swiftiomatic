import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement app — no dock icon, no menu bar.
        // Exists solely to host the Source Editor Extension.
    }
}
