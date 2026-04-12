import Foundation
import Observation
import OSLog
import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

private let logger = Logger(subsystem: "app.toba.swiftiomatic", category: "AppModel")

@Observable
@MainActor
final class AppModel {
    var rules: [RuleConfigurationEntry] = []
    var configuration: Configuration = .default
    var configPath: String?
    var showingConfigPicker = false

    init() {
        rules = Swiftiomatic.ruleCatalog()
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
        case .format, .suggest:
            return true
        }
    }

    func ruleEnabledBinding(for entry: RuleConfigurationEntry) -> Binding<Bool> {
        Binding(
            get: { [self] in isRuleEnabled(entry) },
            set: { [self] _ in toggleRule(entry) }
        )
    }

    func toggleRule(_ entry: RuleConfigurationEntry) {
        guard entry.scope == .lint else { return }
        let enabled = isRuleEnabled(entry)
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
        saveConfig()
    }

    func loadConfig(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            configuration = try Swiftiomatic.loadConfiguration(from: url.path)
            configPath = url.path
        } catch {
            logger.error("Failed to load config: \(error)")
            return
        }

        persistToAppGroup()
    }

    func saveConfig() {
        persistToAppGroup()
    }

    func handleConfigFileSelected(_ result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }
        loadConfig(from: url)
    }

    private func persistToAppGroup() {
        guard let suite = SharedDefaults.suite else { return }
        if let yaml = try? configuration.toYAMLString() {
            suite.set(yaml, forKey: SharedDefaults.configYAMLKey)
        }
        suite.set(configPath, forKey: SharedDefaults.configPathKey)
    }

    private func loadFromAppGroup() {
        guard let suite = SharedDefaults.suite,
            let yaml = suite.string(forKey: SharedDefaults.configYAMLKey)
        else { return }

        configuration = Configuration.fromYAMLString(yaml)
        configPath = suite.string(forKey: SharedDefaults.configPathKey)
    }
}

