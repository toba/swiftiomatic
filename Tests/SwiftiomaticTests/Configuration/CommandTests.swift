import Foundation
import Testing

@testable import SwiftiomaticKit

extension Command {
  fileprivate init?(string: String) {
    let nsString = string.bridge()
    guard nsString.length > 7 else { return nil }
    let subString = nsString.substring(with: NSRange(location: 3, length: nsString.length - 4))
    self.init(commandString: subString, line: 1, range: 4..<nsString.length)
  }
}

@Suite(.rulesRegistered) struct CommandTests {
  // MARK: Command Creation

  @Test func noCommandsInEmptyFile() {
    let file = SwiftSource(contents: "")
    #expect(file.commands() == [])
  }

  @Test func emptyString() {
    #expect(Command(string: "") == nil)
  }

  @Test func disable() {
    let input = "// sm:disable rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .disable,
      ruleIdentifiers: ["rule_id"],
      line: 1,
      range: 4..<22,
    )
    #expect(file.commands() == [expected])
    #expect(Command(string: input) == expected)
  }

  @Test func disablePrevious() {
    let input = "// sm:disable:previous rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<31,
      modifier: .previous,
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func disableThis() {
    let input = "// sm:disable:this rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<27,
      modifier: .this,
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func disableNext() {
    let input = "// sm:disable:next rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<27,
      modifier: .next,
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func enable() {
    let input = "// sm:enable rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .enable,
      ruleIdentifiers: ["rule_id"],
      line: 1,
      range: 4..<21,
    )
    #expect(file.commands() == [expected])
    #expect(Command(string: input) == expected)
  }

  @Test func enablePrevious() {
    let input = "// sm:enable:previous rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<30,
      modifier: .previous,
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func enableThis() {
    let input = "// sm:enable:this rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<26,
      modifier: .this,
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func enableNext() {
    let input = "// sm:enable:next rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<26,
      modifier: .next,
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func disableFile() {
    let input = "// sm:disable:file rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<27,
      modifier: .file,
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func enableFile() {
    let input = "// sm:enable:file rule_id\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<26,
      modifier: .file,
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func disableFileMultipleRules() {
    let input = "// sm:disable:file rule_a rule_b\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .disable, ruleIdentifiers: ["rule_a", "rule_b"], line: 1, range: 4..<33,
      modifier: .file,
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func disableFileWithTrailingComment() {
    let input = "// sm:disable:file rule_id - Legacy code\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<41,
      modifier: .file,
      trailingComment: "Legacy code",
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func trailingComment() {
    let input = "// sm:enable:next rule_id - Comment\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<36,
      modifier: .next,
      trailingComment: "Comment",
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func trailingCommentWithUrl() {
    let input =
      "// sm:enable:next rule_id - Comment with URL https://github.com/realm/SwiftLint\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<80,
      modifier: .next,
      trailingComment: "Comment with URL https://github.com/realm/SwiftLint",
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  @Test func trailingCommentUrlOnly() {
    let input = "// sm:enable:next rule_id - https://github.com/realm/SwiftLint\n"
    let file = SwiftSource(contents: input)
    let expected = Command(
      action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<63,
      modifier: .next,
      trailingComment: "https://github.com/realm/SwiftLint",
    )
    #expect(file.commands() == expected.expand())
    #expect(Command(string: input) == expected)
  }

  // MARK: Action

  @Test func actionInverse() {
    #expect(Command.Action.enable.inverse() == .disable)
    #expect(Command.Action.disable.inverse() == .enable)
  }

  // MARK: Command Expansion

  private let completeLine = 0..<Int.max

  @Test func noModifierCommandExpandsToItself() {
    do {
      let command = Command(action: .disable, ruleIdentifiers: ["rule_id"])
      #expect(command.expand() == [command])
    }
    do {
      let command = Command(action: .enable, ruleIdentifiers: ["rule_id"])
      #expect(command.expand() == [command])
    }
    do {
      let command = Command(action: .disable, ruleIdentifiers: ["1", "2"])
      #expect(command.expand() == [command])
    }
  }

  @Test func expandPreviousCommand() {
    do {
      let command = Command(
        action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
        modifier: .previous,
      )
      let expanded = [
        Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 0),
        Command(
          action: .enable,
          ruleIdentifiers: ["rule_id"],
          line: 0,
          range: completeLine,
        ),
      ]
      #expect(command.expand() == expanded)
    }
    do {
      let command = Command(
        action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
        modifier: .previous,
      )
      let expanded = [
        Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 0),
        Command(
          action: .disable,
          ruleIdentifiers: ["rule_id"],
          line: 0,
          range: completeLine,
        ),
      ]
      #expect(command.expand() == expanded)
    }
    do {
      let command = Command(
        action: .enable, ruleIdentifiers: ["1", "2"], line: 1, range: 4..<48,
        modifier: .previous,
      )
      let expanded = [
        Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 0),
        Command(
          action: .disable,
          ruleIdentifiers: ["1", "2"],
          line: 0,
          range: completeLine,
        ),
      ]
      #expect(command.expand() == expanded)
    }
  }

  @Test func expandThisCommand() {
    do {
      let command = Command(
        action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
        modifier: .this,
      )
      let expanded = [
        Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1),
        Command(
          action: .enable,
          ruleIdentifiers: ["rule_id"],
          line: 1,
          range: completeLine,
        ),
      ]
      #expect(command.expand() == expanded)
    }
    do {
      let command = Command(
        action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
        modifier: .this,
      )
      let expanded = [
        Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1),
        Command(
          action: .disable,
          ruleIdentifiers: ["rule_id"],
          line: 1,
          range: completeLine,
        ),
      ]
      #expect(command.expand() == expanded)
    }
    do {
      let command = Command(
        action: .enable, ruleIdentifiers: ["1", "2"], line: 1, range: 4..<48,
        modifier: .this,
      )
      let expanded = [
        Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 1),
        Command(
          action: .disable,
          ruleIdentifiers: ["1", "2"],
          line: 1,
          range: completeLine,
        ),
      ]
      #expect(command.expand() == expanded)
    }
  }

  @Test func expandNextCommand() {
    do {
      let command = Command(
        action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
        modifier: .next,
      )
      let expanded = [
        Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 2),
        Command(
          action: .enable,
          ruleIdentifiers: ["rule_id"],
          line: 2,
          range: completeLine,
        ),
      ]
      #expect(command.expand() == expanded)
    }
    do {
      let command = Command(
        action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
        modifier: .next,
      )
      let expanded = [
        Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 2),
        Command(
          action: .disable,
          ruleIdentifiers: ["rule_id"],
          line: 2,
          range: completeLine,
        ),
      ]
      #expect(command.expand() == expanded)
    }
    do {
      let command = Command(
        action: .enable, ruleIdentifiers: ["1", "2"], line: 1,
        modifier: .next,
      )
      let expanded = [
        Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 2),
        Command(
          action: .disable,
          ruleIdentifiers: ["1", "2"],
          line: 2,
          range: completeLine,
        ),
      ]
      #expect(command.expand() == expanded)
    }
  }

  @Test func expandFileCommand() {
    do {
      let command = Command(
        action: .disable, ruleIdentifiers: ["rule_id"], line: 5, range: 4..<48,
        modifier: .file,
      )
      let expanded = [
        Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 0),
      ]
      #expect(command.expand() == expanded)
    }
    do {
      let command = Command(
        action: .enable, ruleIdentifiers: ["rule_id"], line: 3, range: 4..<48,
        modifier: .file,
      )
      let expanded = [
        Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 0),
      ]
      #expect(command.expand() == expanded)
    }
    do {
      let command = Command(
        action: .disable, ruleIdentifiers: ["1", "2"], line: 10,
        modifier: .file,
      )
      let expanded = [
        Command(action: .disable, ruleIdentifiers: ["1", "2"], line: 0),
      ]
      #expect(command.expand() == expanded)
    }
  }

  // MARK: Superfluous Disable Command Detection

  @Test func superfluousDisableCommands() async {
    #expect(
      await violations(Example("// sm:disable nesting\nprint(123)\n"))
        .map(\.ruleIdentifier) == [
          "blanket_disable_command",
          "superfluous_disable_command",
        ],
    )
    #expect(
      await violations(Example("// sm:disable:next nesting\nprint(123)\n"))[0].ruleIdentifier
        == "superfluous_disable_command",
    )
    #expect(
      await violations(Example("print(123) // sm:disable:this nesting\n"))[0].ruleIdentifier
        == "superfluous_disable_command",
    )
    #expect(
      await violations(Example("print(123)\n// sm:disable:previous nesting\n"))[0]
        .ruleIdentifier
        == "superfluous_disable_command",
    )
  }

  @Test(.disabled("SuperfluousDisableCommand behavior differs"))
  func disableAllOverridesSuperfluousDisableCommand() async {
    #expect(
      await violations(
        Example(
          """
          print(123)
          """,
        ),
      ).isEmpty,
    )
    #expect(
      await violations(
        Example(
          """
          print(123)
          """,
        ),
      ).isEmpty,
    )
    #expect(
      await violations(
        Example(
          """
          print(123)
          """,
        ),
      ).isEmpty,
    )
    #expect(
      await violations(
        Example(
          "// sm:disable all\n// sm:disable:previous nesting\nprint(123)\n",
        ),
      ).isEmpty,
    )
  }

  @Test func superfluousDisableCommandsFile() async {
    #expect(
      await violations(Example("// sm:disable:file nesting\nprint(123)\n"))
        .map(\.ruleIdentifier) == ["superfluous_disable_command"],
    )
  }

  @Test func superfluousDisableCommandsIgnoreDelimiter() async {
    let longComment = "Comment with a large number of words that shouldn't register as superfluous"
    #expect(
      await violations(Example("// sm:disable nesting - \(longComment)\nprint(123)\n")).map(
        \.ruleIdentifier,
      ) == ["blanket_disable_command", "superfluous_disable_command"],
    )
    #expect(
      await violations(Example("// sm:disable:next nesting - Comment\nprint(123)\n"))[0]
        .ruleIdentifier == "superfluous_disable_command",
    )
    #expect(
      await violations(Example("print(123) // sm:disable:this nesting - Comment\n"))[0]
        .ruleIdentifier == "superfluous_disable_command",
    )
    #expect(
      await violations(Example("print(123)\n// sm:disable:previous nesting - Comment\n"))[0]
        .ruleIdentifier == "superfluous_disable_command",
    )
  }

  @Test func invalidDisableCommands() async {
    #expect(
      await violations(
        Example(
          "// sm:disable nesting_foo\n" + "print(123)\n"
            + "// sm:enable nesting_foo\n",
        ),
      )[0].ruleIdentifier
        == "superfluous_disable_command",
    )
    #expect(
      await violations(Example("// sm:disable:next nesting_foo\nprint(123)\n"))[0]
        .ruleIdentifier == "superfluous_disable_command",
    )
    #expect(
      await violations(Example("print(123) // sm:disable:this nesting_foo\n"))[0]
        .ruleIdentifier == "superfluous_disable_command",
    )
    #expect(
      await violations(Example("print(123)\n// sm:disable:previous nesting_foo\n"))[0]
        .ruleIdentifier == "superfluous_disable_command",
    )

    #expect(
      await violations(Example("print(123)\n// sm:disable:previous nesting_foo \n"))
        .count == 1,
    )

    let example = Example(
      "// sm:disable nesting this is a comment\n// sm:enable nesting\n",
    )
    let multipleViolations = await violations(example)
    #expect(
      multipleViolations
        .count(where: { $0.ruleIdentifier == "superfluous_disable_command" }) == 9,
    )
    #expect(
      multipleViolations
        .count(where: { $0.ruleIdentifier == "blanket_disable_command" }) == 4,
    )

    let onlyNonExistentRulesViolations = await violations(
      Example("// sm:disable this is a comment\n"),
    )
    #expect(
      onlyNonExistentRulesViolations
        .count(where: { $0.ruleIdentifier == "superfluous_disable_command" })
        == 4,
    )
    #expect(
      onlyNonExistentRulesViolations.count(where: {
        $0.ruleIdentifier == "blanket_disable_command"
      }) == 4,
    )

    #expect(
      await violations(Example("print(123)\n// sm:disable:previous nesting_foo\n"))[0].reason
        == "'nesting_foo' is not a valid rule; remove it from the disable command",
    )
  }

  @Test func superfluousDisableCommandsDisabled() async {
    #expect(
      await violations(
        Example(
          "// sm:disable superfluous_disable_command nesting\n" + "print(123)\n"
            + "// sm:enable superfluous_disable_command nesting\n",
        ),
      ) == [],
    )
    #expect(
      await violations(
        Example(
          "// sm:disable superfluous_disable_command\n" + "// sm:disable nesting\n"
            + "print(123)\n" + "// sm:enable superfluous_disable_command nesting\n",
        ),
      ) == [],
    )
    #expect(
      await violations(
        Example(
          "// sm:disable:next superfluous_disable_command nesting\nprint(123)\n",
        ),
      )
        == [],
    )
    #expect(
      await violations(
        Example(
          "print(123) // sm:disable:this superfluous_disable_command nesting\n",
        ),
      ) == [],
    )
    #expect(
      await violations(
        Example(
          "print(123)\n// sm:disable:previous superfluous_disable_command nesting\n",
        ),
      )
        == [],
    )
  }

  @Test func superfluousDisableCommandsDisabledOnConfiguration() async {
    let rulesMode = Configuration.RulesMode.defaultConfiguration(
      disabled: ["superfluous_disable_command"], optIn: [],
    )
    let configuration = Configuration(rulesMode: rulesMode)

    #expect(
      await violations(
        Example(
          "// sm:disable nesting\n" + "print(123)\n" + "// sm:enable nesting\n",
        ),
        config: configuration,
      ) == [],
    )
    #expect(
      await violations(
        Example("// sm:disable:next nesting\nprint(123)\n"),
        config: configuration,
      )
        == [],
    )
    #expect(
      await violations(
        Example("print(123) // sm:disable:this nesting\n"),
        config: configuration,
      )
        == [],
    )
    #expect(
      await violations(
        Example("print(123)\n// sm:disable:previous nesting\n"),
        config: configuration,
      ) == [],
    )
  }

  @Test func superfluousDisableCommandsDisabledWhenAllRulesDisabled() async {
    #expect(
      await violations(
        Example(
          """
          """,
        ),
      ) == [],
    )
    #expect(
      await violations(
        Example(
          """

          """,
        ),
      ) == [],
    )
  }

  @Test func superfluousDisableCommandsInMultilineComments() async {
    #expect(
      await violations(
        Example(
          """
          /*
          let a = 0
          */

          """,
        ),
      ) == [],
    )
  }

  @Test(.disabled("SuperfluousDisableCommand behavior differs"))
  func superfluousDisableCommandsEnabledForAnalyzer() async {
    let configuration = Configuration(
      rulesMode: .defaultConfiguration(
        disabled: [],
        optIn: [UnusedDeclarationRule.identifier],
      ),
    )
    let violations = await violations(
      Example(
        """
        public class Foo {
            func foo() -> Int {
                1
            }
            func bar() {
               foo()
            }
        }
        """,
      ),
      config: configuration,
      requiresFileOnDisk: true,
    )
    #expect(violations.count == 1)
    #expect(violations.first?.ruleIdentifier == "superfluous_disable_command")
    #expect(violations.first?.location.line == 3)
  }
}
