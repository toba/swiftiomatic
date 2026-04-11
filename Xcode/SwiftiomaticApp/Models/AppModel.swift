import Foundation
import Observation
import SwiftiomaticKit

@Observable
@MainActor
final class AppModel {
  var rules: [RuleConfigurationEntry] = []
  var configuration: Configuration = .default
  var configPath: String?
  var showingConfigPicker = false

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
      print("Failed to load config: \(error)")
      return
    }

    persistToAppGroup()
  }

  func saveConfig() {
    persistToAppGroup()
  }

  func handleConfigFileSelected(_ result: Result<URL, any Error>) {
    guard case let .success(url) = result else { return }
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
