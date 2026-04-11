import Foundation

struct InvalidCommandRule: Rule {
  static let id = "invalid_command"
  static let name = "Invalid Command"
  static let summary = "sm: command is invalid"
  static var nonTriggeringExamples: [Example] {
    [
      Example("// sm:disable unused_import"),
      Example("// sm:enable unused_import"),
      Example("// sm:disable:next unused_import"),
      Example("// sm:disable:previous unused_import"),
      Example("// sm:disable:this unused_import"),
      Example("//sm:disable:this unused_import"),
      Example(
        "_ = \"🤵🏼‍♀️\" // sm:disable:this unused_import",
        isExcludedFromDocumentation: true,
      ),
      Example(
        "_ = \"🤵🏼‍♀️ 🤵🏼‍♀️\" // sm:disable:this unused_import",
        isExcludedFromDocumentation: true,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("// ↓sm:"),
      Example("// ↓sm: "),
      Example("// ↓sm::"),
      Example("// ↓sm:: "),
      Example("// ↓sm:disable"),
      Example("// ↓sm:dissable unused_import"),
      Example("// ↓sm:enaaaable unused_import"),
      Example("// ↓sm:disable:nxt unused_import"),
      Example("// ↓sm:enable:prevus unused_import"),
      Example("// ↓sm:enable:ths unused_import"),
      Example("// ↓sm:enable"),
      Example("// ↓sm:enable:"),
      Example("// ↓sm:enable: "),
      Example("// ↓sm:disable: unused_import"),
      Example("// s↓sm:disable unused_import"),
      Example("// 🤵🏼‍♀️sm:disable unused_import", isExcludedFromDocumentation: true),
    ]
  }

  var options = SeverityOption<Self>(.warning)

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
        reason: command.invalidReason() ?? Self.summary,
      )
    }
  }

  private func ruleViolation(for command: Command, in file: SwiftSource, reason: String)
    -> RuleViolation
  {
    RuleViolation(
      ruleType: Self.self,
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
