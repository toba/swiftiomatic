@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantBreakTests: RuleTesting {
  @Test func trailingBreakAfterStatements() {
    assertFormatting(
      DropRedundantBreak.self,
      input: """
        switch x {
        case .a:
          print("a")
          1️⃣break
        case .b:
          print("b")
          2️⃣break
        }
        """,
      expected: """
        switch x {
        case .a:
          print("a")
        case .b:
          print("b")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'break'; switch cases do not fall through by default"),
        FindingSpec("2️⃣", message: "remove redundant 'break'; switch cases do not fall through by default"),
      ]
    )
  }

  @Test func breakAsOnlyStatementNotFlagged() {
    assertFormatting(
      DropRedundantBreak.self,
      input: """
        switch x {
        case .a:
          break
        default:
          break
        }
        """,
      expected: """
        switch x {
        case .a:
          break
        default:
          break
        }
        """,
      findings: []
    )
  }

  @Test func labeledBreakNotFlagged() {
    assertFormatting(
      DropRedundantBreak.self,
      input: """
        outer: switch x {
        case .a:
          print("a")
          break outer
        }
        """,
      expected: """
        outer: switch x {
        case .a:
          print("a")
          break outer
        }
        """,
      findings: []
    )
  }

  @Test func defaultCase() {
    assertFormatting(
      DropRedundantBreak.self,
      input: """
        switch x {
        default:
          print("default")
          1️⃣break
        }
        """,
      expected: """
        switch x {
        default:
          print("default")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'break'; switch cases do not fall through by default"),
      ]
    )
  }

  @Test func noBreakNotFlagged() {
    assertFormatting(
      DropRedundantBreak.self,
      input: """
        switch x {
        case .a:
          print("a")
        case .b:
          print("b")
        }
        """,
      expected: """
        switch x {
        case .a:
          print("a")
        case .b:
          print("b")
        }
        """,
      findings: []
    )
  }

  @Test func breakInMiddleNotFlagged() {
    assertFormatting(
      DropRedundantBreak.self,
      input: """
        switch x {
        case .a:
          if condition {
            break
          }
          print("a")
        }
        """,
      expected: """
        switch x {
        case .a:
          if condition {
            break
          }
          print("a")
        }
        """,
      findings: []
    )
  }
}
