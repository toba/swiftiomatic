@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct CollapseSimpleEnumsTests: RuleTesting {

  @Test func collapsesSimpleEnum() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        1️⃣private enum OptionalPatternKind {
            case chained
            case forced
        }
        """,
      expected: """
        private enum OptionalPatternKind { case chained, forced }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple enum onto a single line"),
      ])
  }

  @Test func collapsesSingleCase() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        1️⃣enum Direction {
            case up
        }
        """,
      expected: """
        enum Direction { case up }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple enum onto a single line"),
      ])
  }

  @Test func collapsesThreeCases() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        1️⃣enum Color {
            case red
            case green
            case blue
        }
        """,
      expected: """
        enum Color { case red, green, blue }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple enum onto a single line"),
      ])
  }

  @Test func preservesAccessModifiers() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        1️⃣internal enum State {
            case loading
            case loaded
            case error
        }
        """,
      expected: """
        internal enum State { case loading, loaded, error }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple enum onto a single line"),
      ])
  }

  @Test func skipsAssociatedValues() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        enum Result {
            case success(Int)
            case failure
        }
        """,
      expected: """
        enum Result {
            case success(Int)
            case failure
        }
        """)
  }

  @Test func skipsRawValues() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        enum Priority: Int {
            case low = 0
            case high = 1
        }
        """,
      expected: """
        enum Priority: Int {
            case low = 0
            case high = 1
        }
        """)
  }

  @Test func skipsEnumWithMethods() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        enum Direction {
            case up
            case down

            var description: String { "dir" }
        }
        """,
      expected: """
        enum Direction {
            case up
            case down

            var description: String { "dir" }
        }
        """)
  }

  @Test func skipsWhenTooLongForOneLine() {
    var config = Configuration.forTesting(enabledRule: CollapseSimpleEnums.key)
    config[LineLength.self] = 40

    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        enum VeryLongEnumNameThatWontFit {
            case somewhatLongCaseName
            case anotherLongCaseName
        }
        """,
      expected: """
        enum VeryLongEnumNameThatWontFit {
            case somewhatLongCaseName
            case anotherLongCaseName
        }
        """,
      configuration: config)
  }

  @Test func alreadyCollapsedUnchanged() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        enum Direction { case up, down }
        """,
      expected: """
        enum Direction { case up, down }
        """)
  }

  @Test func collapsesMultiCaseDeclarations() {
    // Cases already comma-separated in the source but on separate lines
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        1️⃣enum Axis {
            case x, y
            case z
        }
        """,
      expected: """
        enum Axis { case x, y, z }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple enum onto a single line"),
      ])
  }

  @Test func skipsEmptyEnum() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        enum Empty {
        }
        """,
      expected: """
        enum Empty {
        }
        """)
  }

  @Test func collapsesNestedEnum() {
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        struct Foo {
            1️⃣private enum Kind {
                case a
                case b
            }
        }
        """,
      expected: """
        struct Foo {
            private enum Kind { case a, b }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple enum onto a single line"),
      ])
  }

  @Test func skipsEnumWithConformancesButNoRawValues() {
    // Conforming to a protocol is fine — only raw value assignments block collapsing.
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        1️⃣enum Direction: Sendable {
            case up
            case down
        }
        """,
      expected: """
        enum Direction: Sendable { case up, down }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple enum onto a single line"),
      ])
  }

  @Test func skipsRawValueTypeEnum() {
    // String raw value type implies raw values even without explicit assignments.
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        enum Direction: String {
            case up
            case down
        }
        """,
      expected: """
        enum Direction: String {
            case up
            case down
        }
        """)
  }

  @Test func collapsesNestedEnumInsideNonCollapsibleEnum() {
    // The outer enum has methods so it can't collapse, but the inner CodingKeys
    // enum should still be visited and collapsed.
    assertFormatting(
      CollapseSimpleEnums.self,
      input: """
        enum Indent: Codable {
            case tabs(Int)
            case spaces(Int)

            1️⃣private enum CodingKeys: CodingKey {
                case tabs
                case spaces
            }

            func encode(to encoder: Encoder) throws {}
        }
        """,
      expected: """
        enum Indent: Codable {
            case tabs(Int)
            case spaces(Int)

            private enum CodingKeys: CodingKey { case tabs, spaces }

            func encode(to encoder: Encoder) throws {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "collapse simple enum onto a single line"),
      ])
  }
}
