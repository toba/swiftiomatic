import Foundation
import OSLog
import SwiftUI
import SwiftiomaticKit
import SwiftiomaticSyntax
import UniformTypeIdentifiers

private let logger = Logger(subsystem: "app.toba.swiftiomatic", category: "Document")

@Observable
final class SwiftiomaticDocument: ReferenceFileDocument {
    var configuration: Configuration
    let rules: [RuleConfigurationEntry]

    typealias Snapshot = String

    nonisolated static var readableContentTypes: [UTType] { [.yaml] }

    init() {
        self.configuration = .default
        self.rules = Swiftiomatic.ruleCatalog()
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
            let yaml = String(data: data, encoding: .utf8)
        else {
            throw SwiftiomaticError.yamlParsing("The file could not be read as UTF-8 text.")
        }
        self.configuration = try Configuration.parse(yaml: yaml)
        self.rules = Swiftiomatic.ruleCatalog()
    }

    func snapshot(contentType _: UTType) throws -> String {
        let yaml = try configuration.toYAMLString()
        syncToExtension(yaml: yaml)
        return yaml
    }

    nonisolated func fileWrapper(
        snapshot: String,
        configuration _: WriteConfiguration
    ) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(snapshot.utf8))
    }

    // MARK: - Rule Toggle

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
    }

    // MARK: - Extension Sync

    private func syncToExtension(yaml: String) {
        guard let suite = SharedDefaults.suite else { return }
        suite.set(yaml, forKey: SharedDefaults.configYAMLKey)
    }
}
