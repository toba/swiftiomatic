import AppKit
import SwiftUI

/// Zero-size NSView that captures a reference to its hosting NSWindow.
struct WindowAccessor: NSViewRepresentable {
    var onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            onWindow(window)
        }
    }
}

/// Overrides the DocumentGroup window title with the parent folder name,
/// re-applying it via KVO whenever the framework resets it.
struct ParentFolderTitleModifier: ViewModifier {
    let fileURL: URL?
    @State private var observation: NSKeyValueObservation?

    private var desiredTitle: String? {
        guard let url = fileURL else { return nil }
        let folder = url.deletingLastPathComponent().lastPathComponent
        guard !folder.isEmpty, folder != "/" else { return nil }
        return folder
    }

    func body(content: Content) -> some View {
        content.background(
            WindowAccessor { window in
                guard let title = desiredTitle else { return }
                if window.title != title {
                    window.title = title
                }
                if observation == nil {
                    observation = window.observe(\.title, options: .new) { win, change in
                        if let newTitle = change.newValue, newTitle != title {
                            win.title = title
                        }
                    }
                }
            }
        )
    }
}

extension View {
    func parentFolderWindowTitle(fileURL: URL?) -> some View {
        modifier(ParentFolderTitleModifier(fileURL: fileURL))
    }
}

