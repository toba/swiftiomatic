import AppKit
import Observation
import Swiftiomatic
import UniformTypeIdentifiers

@Observable
@MainActor
final class AppModel {
    var rules: [RuleConfigurationEntry] = []
    var configuration: Configuration = .default
    var configPath: String?
    var configBookmark: Data?

    var lintRules: [RuleConfigurationEntry] {
        rules.filter { $0.scope == .lint }
    }

    var formatRules: [RuleConfigurationEntry] {
        rules.filter { $0.scope == .format }
    }

    var suggestRules: [RuleConfigurationEntry] {
        rules.filter { $0.scope == .suggest }
    }

    init() {
        rules = SwiftiomaticLib.ruleCatalog()
        loadFromAppGroup()
    }

    func isRuleEnabled(_ entry: RuleConfigurationEntry) -> Bool {
        switch entry.scope {
            case .lint:
                if configuration.disabledLintRules.contains(entry.id) { return false }
                if entry.isOptIn {
                    return configuration.enabledLintRules.contains(entry.id)
                }
                return true
            case .format:
                if configuration.disabledFormatRules.contains(entry.id) { return false }
                if entry.isOptIn {
                    return configuration.enabledFormatRules.contains(entry.id)
                }
                return true
            case .suggest:
                return true
        }
    }

    func toggleRule(_ entry: RuleConfigurationEntry) {
        let enabled = isRuleEnabled(entry)
        switch entry.scope {
            case .lint:
                if enabled {
                    configuration.enabledLintRules.removeAll { $0 == entry.id }
                    if !entry.isOptIn {
                        configuration.disabledLintRules.append(entry.id)
                    }
                } else {
                    configuration.disabledLintRules.removeAll { $0 == entry.id }
                    if entry.isOptIn {
                        configuration.enabledLintRules.append(entry.id)
                    }
                }
            case .format:
                if enabled {
                    configuration.enabledFormatRules.removeAll { $0 == entry.id }
                    if !entry.isOptIn {
                        configuration.disabledFormatRules.append(entry.id)
                    }
                } else {
                    configuration.disabledFormatRules.removeAll { $0 == entry.id }
                    if entry.isOptIn {
                        configuration.enabledFormatRules.append(entry.id)
                    }
                }
            case .suggest:
                break
        }
        saveConfig()
    }

    func loadConfig(from url: URL) {
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            configBookmark = bookmark
            configPath = url.path

            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            configuration = try SwiftiomaticLib.loadConfiguration(from: url.path)

            // Persist to App Group
            if let suite = SharedDefaults.suite {
                suite.set(bookmark, forKey: SharedDefaults.configBookmarkKey)
                suite.set(url.path, forKey: SharedDefaults.configPathKey)
            }
        } catch {
            print("Failed to load config: \(error)")
        }
    }

    func saveConfig() {
        guard let bookmark = configBookmark else { return }
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            bookmarkDataIsStale: &stale
        ), url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        try? SwiftiomaticLib.saveConfiguration(configuration, to: url.path)
    }

    func selectConfigFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.yaml]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose Swiftiomatic Configuration"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadConfig(from: url)
    }

    private func loadFromAppGroup() {
        guard let suite = SharedDefaults.suite,
              let bookmark = suite.data(forKey: SharedDefaults.configBookmarkKey) else {
            return
        }
        configBookmark = bookmark
        configPath = suite.string(forKey: SharedDefaults.configPathKey)

        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            bookmarkDataIsStale: &stale
        ), url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        configuration = (try? SwiftiomaticLib.loadConfiguration(from: url.path)) ?? .default
    }
}
