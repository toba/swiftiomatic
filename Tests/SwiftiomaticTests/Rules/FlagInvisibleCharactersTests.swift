@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagInvisibleCharactersTests: RuleTesting {
  @Test func zeroWidthSpace() {
    assertLint(
      FlagInvisibleCharacters.self,
      "let s = 1️⃣\"Hello\u{200B}World\"",
      findings: [
        FindingSpec("1️⃣", message: "string literal contains invisible character U+200B (zero-width space)"),
      ]
    )
  }

  @Test func zeroWidthNonJoiner() {
    assertLint(
      FlagInvisibleCharacters.self,
      "let s = 1️⃣\"Hello\u{200C}World\"",
      findings: [
        FindingSpec("1️⃣", message: "string literal contains invisible character U+200C (zero-width non-joiner)"),
      ]
    )
  }

  @Test func byteOrderMark() {
    assertLint(
      FlagInvisibleCharacters.self,
      "let s = 1️⃣\"Hello\u{FEFF}World\"",
      findings: [
        FindingSpec("1️⃣", message: "string literal contains invisible character U+FEFF (zero-width no-break space)"),
      ]
    )
  }

  @Test func multipleInvisiblesInOneString() {
    // Two adjacent markers both resolve to the literal's start position;
    // the rule emits one finding per invisible character, so both markers
    // match.
    assertLint(
      FlagInvisibleCharacters.self,
      "let s = 1️⃣2️⃣\"A\u{200B}B\u{FEFF}C\"",
      findings: [
        FindingSpec("1️⃣", message: "string literal contains invisible character U+200B (zero-width space)"),
        FindingSpec("2️⃣", message: "string literal contains invisible character U+FEFF (zero-width no-break space)"),
      ]
    )
  }

  @Test func plainStringDoesNotTrigger() {
    assertLint(
      FlagInvisibleCharacters.self,
      """
      let s = "HelloWorld"
      let t = "Hello World"
      let u = "Hello\\tWorld"
      let v = "Hello\\nWorld"
      let w = "Hello 👋 World"
      """,
      findings: []
    )
  }

  @Test func emptyStringDoesNotTrigger() {
    assertLint(
      FlagInvisibleCharacters.self,
      """
      let s = ""
      """,
      findings: []
    )
  }

  @Test func multilineWithInvisibleChar() {
    assertLint(
      FlagInvisibleCharacters.self,
      "let m = 1️⃣\"\"\"\nHello\u{200B}World\n\"\"\"",
      findings: [
        FindingSpec("1️⃣", message: "string literal contains invisible character U+200B (zero-width space)"),
      ]
    )
  }

  @Test func interpolationWithInvisibleChar() {
    assertLint(
      FlagInvisibleCharacters.self,
      "let s = 1️⃣\"He\u{200C}llo \\(name)\"",
      findings: [
        FindingSpec("1️⃣", message: "string literal contains invisible character U+200C (zero-width non-joiner)"),
      ]
    )
  }
}
