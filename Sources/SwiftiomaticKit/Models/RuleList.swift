import SwiftiomaticSyntax

/// A rule paired with whether it was initialized with a non-empty configuration.
struct ConfiguredRule: Sendable {
  let rule: any Rule
  let initializedWithNonEmptyConfiguration: Bool
}

/// All possible rule list configuration errors.
enum RuleListError: Error {
  /// The rule list contains more than one configuration for the specified rule.
  case duplicatedConfigurations(rule: any Rule.Type)
}

/// A list of available rules.
struct RuleList: Sendable {
  /// The rules contained in this list.
  let rules: [String: any Rule.Type]
  private let aliases: [String: String]

  // MARK: - Initializers

  /// Creates a `RuleList` by specifying all its rules.
  ///
  /// - Parameters:
  ///   - rules: The rules to be contained in this list.
  init(rules: any Rule.Type...) {
    self.init(rules: rules)
  }

  /// Creates a `RuleList` by specifying all its rules.
  ///
  /// - Parameters:
  ///   - rules: The rules to be contained in this list.
  init(rules: [any Rule.Type]) {
    var tmpList = [String: any Rule.Type]()
    var tmpAliases = [String: String]()

    for rule in rules {
      let identifier = rule.identifier
      tmpList[identifier] = rule
      for alias in rule.ruleDeprecatedAliases {
        tmpAliases[alias] = identifier
      }
      tmpAliases[identifier] = identifier
    }
    self.rules = tmpList
    aliases = tmpAliases
  }

  // MARK: - Internal

  func allRulesWrapped(configurationDict: [String: Any] = [:])
    throws(RuleListError) -> [ConfiguredRule]
  {
    var configured = [String: ConfiguredRule]()

    // Add rules where configuration exists
    for (key, configuration) in configurationDict {
      guard let identifier = identifier(for: key),
        let ruleType = rules[identifier]
      else { continue }
      guard configured[identifier] == nil
      else { throw .duplicatedConfigurations(rule: ruleType) }
      do {
        let configuredRule = try ruleType.init(configuration: configuration)
        let isConfigured =
          (configuration as? [String: Any])?.isEmpty == false
          || ([Any].array(of: configuration))?.isEmpty == false
        configured[identifier] = ConfiguredRule(
          rule: configuredRule,
          initializedWithNonEmptyConfiguration: isConfigured,
        )
        continue
      } catch let issue as SwiftiomaticError {
        issue.print()
      } catch {
        SwiftiomaticError.invalidConfiguration(ruleID: identifier).print()
      }
      configured[identifier] = ConfiguredRule(
        rule: ruleType.init(), initializedWithNonEmptyConfiguration: false,
      )
    }

    // Add remaining rules without configuring them
    for (identifier, ruleType) in rules where configured[identifier] == nil {
      configured[identifier] = ConfiguredRule(
        rule: ruleType.init(), initializedWithNonEmptyConfiguration: false,
      )
    }

    return Array(configured.values)
  }

  func identifier(for alias: String) -> String? {
    aliases[alias]
  }

  func allValidIdentifiers() -> [String] {
    rules.flatMap { _, rule -> [String] in
      rule.allIdentifiers
    }
  }
}

extension RuleList: Equatable {
  static func == (lhs: RuleList, rhs: RuleList) -> Bool {
    let lhsKeys = Array(lhs.rules.keys.sorted())
    let rhsKeys = Array(rhs.rules.keys.sorted())
    guard lhsKeys == rhsKeys, lhs.aliases == rhs.aliases else {
      return false
    }
    for key in lhsKeys {
      if lhs.rules[key]!.identifier != rhs.rules[key]!.identifier {
        return false
      }
    }
    return true
  }
}
