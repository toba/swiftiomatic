import SwiftUI
import UniformTypeIdentifiers

@main
struct SwiftiomaticApp: App {
    @State private var store = ConfigStore()
    @Environment(\.openWindow) private var openWindow
    @State private var isImporting = false
    @State private var isExporting = false

    var body: some Scene {
        Window("Swiftiomatic", id: "main") {
            ContentView(store: store)
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.yaml],
                    onCompletion: handleImport
                )
                .fileExporter(
                    isPresented: $isExporting,
                    document: YAMLExportDocument(store: store),
                    contentType: .yaml,
                    defaultFilename: ".swiftiomatic.yaml",
                    onCompletion: { _ in }
                )
                .fileDialogBrowserOptions(.includeHiddenFiles)
        }
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Swiftiomatic") {
                    openWindow(id: "about")
                }
            }
            CommandGroup(after: .importExport) {
                Button("Import Configuration…") { isImporting = true }
                    .keyboardShortcut("o")
                Button("Export Configuration…") { isExporting = true }
                    .keyboardShortcut("s")
            }
        }

        Window("About Swiftiomatic", id: "about") {
            AboutView()
        }
        .windowBackgroundDragBehavior(.enabled)
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
    }

    private func handleImport(_ result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }
        try? store.importYAML(from: url)
    }
}

/// Thin wrapper so `.fileExporter` can write the current YAML.
struct YAMLExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.yaml] }

    private let yaml: String

    @MainActor
    init(store: ConfigStore) {
        self.yaml = (try? store.configuration.toYAMLString()) ?? ""
    }

    init(configuration: ReadConfiguration) throws {
        yaml = ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(yaml.utf8))
    }
}
