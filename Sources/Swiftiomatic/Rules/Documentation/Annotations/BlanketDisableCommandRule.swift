import Foundation

struct BlanketDisableCommandRule: Rule, SyntaxOnlyRule {
  var options = BlanketDisableCommandOptions()

  static let configuration = BlanketDisableCommandConfiguration()

  func validate(file: SwiftSource) -> [RuleViolation] {
    var violations: [RuleViolation] = []
    var ruleIdentifierToCommandMap: [RuleIdentifier: Command] = [:]
    var disabledRuleIdentifiers: Set<RuleIdentifier> = []

    for command in file.commands {
      if command.action == .disable {
        violations += validateAlreadyDisabledRules(
          for: command,
          in: file,
          disabledRuleIdentifiers: disabledRuleIdentifiers,
        )
      }

      if command.action == .enable {
        violations += validateAlreadyEnabledRules(
          for: command,
          in: file,
          disabledRuleIdentifiers: disabledRuleIdentifiers,
        )
      }

      if command.modifier != nil {
        continue
      }

      if command.action == .disable {
        disabledRuleIdentifiers.formUnion(command.ruleIdentifiers)
        command.ruleIdentifiers.forEach { ruleIdentifierToCommandMap[$0] = command }
      }
      if command.action == .enable {
        disabledRuleIdentifiers.subtract(command.ruleIdentifiers)
        command.ruleIdentifiers
          .forEach { ruleIdentifierToCommandMap.removeValue(forKey: $0) }
      }
    }

    violations += validateBlanketDisables(
      in: file,
      disabledRuleIdentifiers: disabledRuleIdentifiers,
      ruleIdentifierToCommandMap: ruleIdentifierToCommandMap,
    )
    violations += validateAlwaysBlanketDisable(file: file)

    return violations
  }

  private func violation(
    for command: Command,
    ruleIdentifier: RuleIdentifier,
    in file: SwiftSource,
    reason: String,
  ) -> RuleViolation {
    violation(
      for: command, ruleIdentifier: ruleIdentifier.stringRepresentation, in: file,
      reason: reason,
    )
  }

  private func violation(
    for command: Command,
    ruleIdentifier: String,
    in file: SwiftSource,
    reason: String,
  ) -> RuleViolation {
    RuleViolation(
      configuration: Self.configuration,
      severity: options.severity,
      location: command.location(of: ruleIdentifier, in: file),
      reason: reason,
    )
  }

  private func validateAlreadyDisabledRules(
    for command: Command,
    in file: SwiftSource,
    disabledRuleIdentifiers: Set<RuleIdentifier>,
  ) -> [RuleViolation] {
    let alreadyDisabledRuleIdentifiers = command.ruleIdentifiers.intersection(
      disabledRuleIdentifiers,
    )
    return alreadyDisabledRuleIdentifiers.map {
      let reason = "The disabled '\($0.stringRepresentation)' rule was already disabled"
      return violation(for: command, ruleIdentifier: $0, in: file, reason: reason)
    }
  }

  private func validateAlreadyEnabledRules(
    for command: Command,
    in file: SwiftSource,
    disabledRuleIdentifiers: Set<RuleIdentifier>,
  ) -> [RuleViolation] {
    let notDisabledRuleIdentifiers = command.ruleIdentifiers
      .subtracting(disabledRuleIdentifiers)
    return notDisabledRuleIdentifiers.map {
      let reason = "The enabled '\($0.stringRepresentation)' rule was not disabled"
      return violation(for: command, ruleIdentifier: $0, in: file, reason: reason)
    }
  }

  private func validateBlanketDisables(
    in file: SwiftSource,
    disabledRuleIdentifiers: Set<RuleIdentifier>,
    ruleIdentifierToCommandMap: [RuleIdentifier: Command],
  ) -> [RuleViolation] {
    let allowedRuleIdentifiers = options.allowedRuleIdentifiers.union(
      options.alwaysBlanketDisableRuleIdentifiers,
    )
    return disabledRuleIdentifiers.compactMap { disabledRuleIdentifier in
      if allowedRuleIdentifiers.contains(disabledRuleIdentifier.stringRepresentation) {
        return nil
      }

      if let command = ruleIdentifierToCommandMap[disabledRuleIdentifier] {
        let reason = """
          Use 'next', 'this' or 'previous' instead to disable the \
          '\(disabledRuleIdentifier.stringRepresentation)' rule once, \
          or re-enable it as soon as possible`
          """
        return violation(
          for: command, ruleIdentifier: disabledRuleIdentifier, in: file, reason: reason,
        )
      }
      return nil
    }
  }

  private func validateAlwaysBlanketDisable(file: SwiftSource) -> [RuleViolation] {
    var violations: [RuleViolation] = []

    guard options.alwaysBlanketDisableRuleIdentifiers.isEmpty == false else {
      return []
    }

    for command in file.commands {
      let ruleIdentifiers: Set<String> = Set(
        command.ruleIdentifiers
          .map(\.stringRepresentation))
      let intersection = ruleIdentifiers.intersection(
        options.alwaysBlanketDisableRuleIdentifiers,
      )
      if command.action == .enable {
        violations.append(
          contentsOf: intersection.map {
            let reason =
              "The '\($0)' rule applies to the whole file and thus doesn't need to be re-enabled"
            return violation(for: command, ruleIdentifier: $0, in: file, reason: reason)
          },
        )
      } else if command.modifier != nil {
        violations.append(
          contentsOf: intersection.map {
            let reason =
              "The '\($0)' rule applies to the whole file and thus cannot be disabled locally "
              + "with 'previous', 'this' or 'next'"
            return violation(for: command, ruleIdentifier: $0, in: file, reason: reason)
          },
        )
      }
    }

    return violations
  }
}

extension Command {
  fileprivate func location(of ruleIdentifier: String, in file: SwiftSource) -> Location {
    var location = range?.upperBound
    if line > 0, line <= file.lines.count {
      let line = file.lines[line - 1].content
      if let ruleIdentifierIndex = line.range(of: ruleIdentifier)?.lowerBound {
        location = line.distance(from: line.startIndex, to: ruleIdentifierIndex) + 1
      }
    }
    return Location(file: file.file.path, line: line, column: location)
  }
}
