import Foundation

struct InvalidCommandRule: Rule, SyntaxOnlyRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = InvalidCommandConfiguration()

  func validate(file: SwiftSource) -> [RuleViolation] {
    badPrefixViolations(in: file) + invalidCommandViolations(in: file)
  }

  private func badPrefixViolations(in file: SwiftSource) -> [RuleViolation] {
    (file.commands + file.invalidCommands).compactMap { command in
      command.isPrecededByInvalidCharacter(in: file)
        ? ruleViolation(
          for: command,
          in: file,
          reason: "sm: command should be preceded by whitespace or a comment character",
        )
        : nil
    }
  }

  private func invalidCommandViolations(in file: SwiftSource) -> [RuleViolation] {
    file.invalidCommands.map { command in
      ruleViolation(
        for: command, in: file,
        reason: command.invalidReason() ?? Self.configuration.summary,
      )
    }
  }

  private func ruleViolation(for command: Command, in file: SwiftSource, reason: String)
    -> RuleViolation
  {
    RuleViolation(
      configuration: Self.configuration,
      severity: options.severity,
      location: Location(
        file: file.path,
        line: command.line,
        column: command.range?.lowerBound,
      ),
      reason: reason,
    )
  }
}

extension Command {
  fileprivate func isPrecededByInvalidCharacter(in file: SwiftSource) -> Bool {
    guard line > 0, let character = range?.lowerBound, character > 1, line <= file.lines.count
    else {
      return false
    }
    let line = file.lines[line - 1].content
    guard line.count > character,
      let char = line[line.index(line.startIndex, offsetBy: character - 2)].unicodeScalars
        .first
    else {
      return false
    }
    return !CharacterSet.whitespaces.union(CharacterSet(charactersIn: "/")).contains(char)
  }

  fileprivate func invalidReason() -> String? {
    if action == .invalid {
      return "sm: command does not have a valid action"
    }
    if modifier == .invalid {
      return "sm: command does not have a valid modifier"
    }
    if ruleIdentifiers.isEmpty {
      return "sm: command does not specify any rules"
    }
    return nil
  }
}
