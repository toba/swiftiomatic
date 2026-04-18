@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct SortSwitchCasesTests: RuleTesting {

  // MARK: - Basic sorting

  @Test func sortEnumCases() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch self {
        1️⃣case .b, .a, .c, .e, .d:
          return nil
        }
        """,
      expected: """
        switch self {
        case .a, .b, .c, .d, .e:
          return nil
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort switch case items alphabetically"),
      ]
    )
  }

  @Test func alreadySorted() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch self {
        case .a, .b, .c:
          break
        }
        """,
      expected: """
        switch self {
        case .a, .b, .c:
          break
        }
        """,
      findings: []
    )
  }

  @Test func singleCaseDoesNothing() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch self {
        case "a":
          break
        }
        """,
      expected: """
        switch self {
        case "a":
          break
        }
        """,
      findings: []
    )
  }

  // MARK: - String literals

  @Test func sortStringLiterals() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch self {
        1️⃣case "GET", "POST", "PUT", "DELETE":
          break
        }
        """,
      expected: """
        switch self {
        case "DELETE", "GET", "POST", "PUT":
          break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort switch case items alphabetically"),
      ]
    )
  }

  // MARK: - Numeric literals

  @Test func sortNumericCases() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch foo {
        1️⃣case 12, 3, 5, 7, 8, 10, 1:
          break
        }
        """,
      expected: """
        switch foo {
        case 1, 3, 5, 7, 8, 10, 12:
          break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort switch case items alphabetically"),
      ]
    )
  }

  @Test func sortHexLiteralCasesAlreadySorted() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch value {
        case 0x30 ... 0x39,
             0x0300 ... 0x036F,
             0x1DC0 ... 0x1DFF,
             0x20D0 ... 0x20FF,
             0xFE20 ... 0xFE2F:
          return true
        default:
          return false
        }
        """,
      expected: """
        switch value {
        case 0x30 ... 0x39,
             0x0300 ... 0x036F,
             0x1DC0 ... 0x1DFF,
             0x20D0 ... 0x20FF,
             0xFE20 ... 0xFE2F:
          return true
        default:
          return false
        }
        """,
      findings: []
    )
  }

  @Test func mixedNumericBaseAlreadySorted() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch value {
        case 0o3,
             0x20,
             110,
             0b1111110:
          return true
        default:
          return false
        }
        """,
      expected: """
        switch value {
        case 0o3,
             0x20,
             110,
             0b1111110:
          return true
        default:
          return false
        }
        """,
      findings: []
    )
  }

  // MARK: - Where clause handling

  @Test func whereClauseOnLastAfterSort() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch self {
        1️⃣case .b, .c where isTrue, .a:
          break
        }
        """,
      expected: """
        switch self {
        case .a, .b, .c where isTrue:
          break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort switch case items alphabetically"),
      ]
    )
  }

  @Test func whereClauseNotOnLastAfterSort() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch self {
        case .b, .c, .a where isTrue:
          break
        }
        """,
      expected: """
        switch self {
        case .b, .c, .a where isTrue:
          break
        }
        """,
      findings: []
    )
  }

  // MARK: - Multiline

  @Test func sortMultilineCases() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch self {
        1️⃣case let .type,
             let .conditionalCompilation:
          break
        }
        """,
      expected: """
        switch self {
        case let .conditionalCompilation,
             let .type:
          break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort switch case items alphabetically"),
      ]
    )
  }

  // MARK: - Nested switch

  @Test func nestedSwitchDoesNotInterfere() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch result {
        case let .success(value):
          switch result {
          case .success:
            print("success")
          case .value:
            print("value")
          }
        case .failure:
          print("fail")
        }
        """,
      expected: """
        switch result {
        case let .success(value):
          switch result {
          case .success:
            print("success")
          case .value:
            print("value")
          }
        case .failure:
          print("fail")
        }
        """,
      findings: []
    )
  }

  // MARK: - Tuples

  @Test func sortTupleCases() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch foo {
        1️⃣case (.foo, _),
             (.bar, _),
             (.baz, _),
             (_, .foo):
        break
        }
        """,
      expected: """
        switch foo {
        case (_, .foo),
             (.bar, _),
             (.baz, _),
             (.foo, _):
        break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort switch case items alphabetically"),
      ]
    )
  }

  // MARK: - Shortest first

  @Test func shortestPatternFirst() {
    assertFormatting(
      SortSwitchCases.self,
      input: """
        switch foo {
        1️⃣case let .fooAndBar(baz, quux),
             let .foo(baz):
        break
        }
        """,
      expected: """
        switch foo {
        case let .foo(baz),
             let .fooAndBar(baz, quux):
        break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort switch case items alphabetically"),
      ]
    )
  }
}
