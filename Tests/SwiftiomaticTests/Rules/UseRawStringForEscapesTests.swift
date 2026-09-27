@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseRawStringForEscapesTests: RuleTesting {
  private static let message =
    "write this literal as a raw string such as #\"...\"# so its quotes and backslashes need no escapes"

  @Test func escapedQuotesWithInterpolation() {
    assertLint(
      UseRawStringForEscapes.self,
      #"""
      throw ProfileError.invalidConfig(
        1️⃣"aliases \"\(owner)\" and \"\(name)\" share the path \(path)")
      """#,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func escapedJSON() {
    assertLint(
      UseRawStringForEscapes.self,
      #"""
      let json = 1️⃣"{\"name\": \"John\", \"age\": 30}"
      """#,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func quoteBeforePoundSuggestsTwoPounds() {
    // `#"...#fff"#` would end at `"#` , so the raw form needs two pounds.
    assertLint(
      UseRawStringForEscapes.self,
      #"""
      let json = 1️⃣"{\"c\":\"#fff\"}"
      let css = 2️⃣"{\"c\":\"##fff\"}"
      """#,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "write this literal as a raw string such as ##\"...\"## so its quotes and backslashes need no escapes"
        ),
        FindingSpec(
          "2️⃣",
          message:
            "write this literal as a raw string such as ###\"...\"### so its quotes and backslashes need no escapes"
        ),
      ]
    )
  }

  @Test func escapedBackslashes() {
    assertLint(
      UseRawStringForEscapes.self,
      #"""
      let pattern = 1️⃣"\\d+\\.\\d+"
      """#,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func fewEscapesNotFlagged() {
    assertLint(
      UseRawStringForEscapes.self,
      #"""
      let a = "alias \"\(name)\": cli is required"
      let b = "C:\\Users"
      let c = "plain text"
      """#,
      findings: []
    )
  }

  @Test func otherEscapesNotFlagged() {
    // A raw string would need `\#n` for the newline, which reads no better.
    assertLint(
      UseRawStringForEscapes.self,
      #"""
      let a = "\"one\"\n\"two\""
      let b = "\"x\"\t\"y\""
      """#,
      findings: []
    )
  }

  @Test func rawStringNotFlagged() {
    assertLint(
      UseRawStringForEscapes.self,
      ##"""
      let a = #"{"name": "John", "age": 30}"#
      let b = #"a \"quoted\" \"word\" here"#
      """##,
      findings: []
    )
  }
}
