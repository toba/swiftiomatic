import Foundation
import OSLog
import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax

private let logger = Logger(subsystem: "app.toba.swiftiomatic", category: "ConfigStore")

/// Loads and saves the shared configuration via UserDefaults.
///
/// The Xcode extension reads from the same suite, so every change here
/// is immediately visible to Format / Lint commands.
@Observable
@MainActor
final class ConfigStore {
    var configuration: Configuration {
        didSet { save() }
    }

    let rules: [RuleConfigurationEntry]

    init() {
        if let suite = SharedDefaults.suite,
            let yaml = suite.string(forKey: SharedDefaults.configYAMLKey)
        {
            self.configuration = Configuration.fromYAMLString(yaml)
        } else {
            self.configuration = .default
        }
        self.rules = Swiftiomatic.ruleCatalog()
    }

    // MARK: - Persistence

    private func save() {
        guard let suite = SharedDefaults.suite else {
            logger.warning("Could not open UserDefaults suite")
            return
        }
        do {
            let yaml = try configuration.toYAMLString()
            suite.set(yaml, forKey: SharedDefaults.configYAMLKey)
        } catch {
            logger.error("Failed to serialize configuration: \(error)")
        }
    }

    // MARK: - Import / Export

    func importYAML(from url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw SwiftiomaticError.yamlParsing("Could not access the file.")
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        guard let yaml = String(data: data, encoding: .utf8) else {
            throw SwiftiomaticError.yamlParsing("The file could not be read as UTF-8 text.")
        }
        configuration = try Configuration.parse(yaml: yaml)
    }

    func exportYAML(to url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw SwiftiomaticError.yamlParsing("Could not access the file.")
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let yaml = try configuration.toYAMLString()
        try Data(yaml.utf8).write(to: url)
    }

    // MARK: - Rule Toggle

    func isRuleEnabled(_ entry: RuleConfigurationEntry) -> Bool {
        if configuration.disabledLintRules.contains(entry.id) { return false }
        if entry.isOptIn {
            return configuration.enabledLintRules.contains(entry.id)
        }
        return true
    }

    func ruleEnabledBinding(for entry: RuleConfigurationEntry) -> Binding<Bool> {
        Binding(
            get: { [self] in isRuleEnabled(entry) },
            set: { [self] _ in toggleRule(entry) }
        )
    }

    func toggleRule(_ entry: RuleConfigurationEntry) {
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
    }
}
