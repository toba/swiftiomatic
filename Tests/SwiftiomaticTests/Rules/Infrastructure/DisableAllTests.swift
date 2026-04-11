import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct DisableAllTests {
  /// Example violations. Could be replaced with other single violations.
  private let violatingPhrases = [
    Example("let r = 0"),  // Violates identifier_name
    Example(#"let myString:String = """#),  // Violates colon_whitespace
    Example("// TODO: Some todo"),  // Violates todo
  ]

  // MARK: Violating Phrase

  /// Tests whether example violating phrases trigger when not applying disable rule
  @Test func violatingPhrase() async {
    for violatingPhrase in violatingPhrases {
      #expect(
        await violations(violatingPhrase.with(code: violatingPhrase.code + "\n")).count == 1,
      )
    }
  }

  // MARK: Enable / Disable Base

  /// Tests whether sm:disable all protects properly
  @Test func disableAll() async {
    for violatingPhrase in violatingPhrases {
      let code = "// sm:disable all\n" + violatingPhrase.code + "\n// sm:enable all\n"
      let protectedPhrase = violatingPhrase.with(code: code)
      #expect(
        await violations(protectedPhrase).isEmpty,
      )
    }
  }

  /// Tests whether sm:enable all unprotects properly
  @Test func enableAll() async {
    for violatingPhrase in violatingPhrases {
      let unprotectedPhrase = violatingPhrase.with(
        code: """
          // sm:disable all
          \(violatingPhrase.code)
          // sm:enable all
          \(violatingPhrase.code)\n
          """,
      )
      #expect(
        await violations(unprotectedPhrase).count == 1,
      )
    }
  }

  // MARK: Enable / Disable Previous

  /// Tests whether sm:disable:previous all protects properly
  @Test func disableAllPrevious() async {
    for violatingPhrase in violatingPhrases {
      let protectedPhrase =
        violatingPhrase
        .with(
          code: """
            \(violatingPhrase.code)
            // sm:disable:previous all\n
            """,
        )
      #expect(
        await violations(protectedPhrase).isEmpty,
      )
    }
  }

  /// Tests whether sm:enable:previous all unprotects properly
  @Test func enableAllPrevious() async {
    for violatingPhrase in violatingPhrases {
      let unprotectedPhrase = violatingPhrase.with(
        code: """
          // sm:disable all
          \(violatingPhrase.code)
          \(violatingPhrase.code)
          // sm:enable:previous all
          // sm:enable all
          """,
      )
      #expect(
        await violations(unprotectedPhrase).count == 1,
      )
    }
  }

  // MARK: Enable / Disable Next

  /// Tests whether sm:disable:next all protects properly
  @Test func disableAllNext() async {
    for violatingPhrase in violatingPhrases {
      let protectedPhrase = violatingPhrase.with(
        code: "// sm:disable:next all\n" + violatingPhrase.code,
      )
      #expect(
        await violations(protectedPhrase).isEmpty,
      )
    }
  }

  /// Tests whether sm:enable:next all unprotects properly
  @Test func enableAllNext() async {
    for violatingPhrase in violatingPhrases {
      let unprotectedPhrase = violatingPhrase.with(
        code: """
          // sm:disable all
          \(violatingPhrase.code)
          // sm:enable:next all
          \(violatingPhrase.code)
          // sm:enable all
          """,
      )
      #expect(
        await violations(unprotectedPhrase).count == 1,
      )
    }
  }

  // MARK: Enable / Disable This

  /// Tests whether sm:disable:this all protects properly
  @Test func disableAllThis() async {
    for violatingPhrase in violatingPhrases {
      let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
      let protectedPhrase = violatingPhrase.with(
        code: rawViolatingPhrase + "// sm:disable:this all\n",
      )
      #expect(
        await violations(protectedPhrase).isEmpty,
      )
    }
  }

  /// Tests whether sm:enable:next all unprotects properly
  @Test func enableAllThis() async {
    for violatingPhrase in violatingPhrases {
      let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
      let unprotectedPhrase = violatingPhrase.with(
        code: """
          // sm:disable all
          \(violatingPhrase.code)
          \(rawViolatingPhrase)// sm:enable:this all
          // sm:enable all
          """,
      )
      #expect(
        await violations(unprotectedPhrase).count == 1,
      )
    }
  }
}
