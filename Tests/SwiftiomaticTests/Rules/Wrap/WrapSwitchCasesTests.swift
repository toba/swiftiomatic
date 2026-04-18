@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapSwitchCasesTests: RuleTesting {

  @Test func multilineSwitchCases() {
    assertFormatting(
      WrapCompoundCaseStatements.self,
      input: """
        func foo() {
            switch bar {
            1️⃣case .a(_), .b, "c":
                print("")
            case .d:
                print("")
            }
        }
        """,
      expected: """
        func foo() {
            switch bar {
            case .a(_),
                 .b,
                 "c":
                print("")
            case .d:
                print("")
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap comma-delimited switch case items onto separate lines")])
  }

  @Test func singleCaseItemUnchanged() {
    assertFormatting(
      WrapCompoundCaseStatements.self,
      input: """
        switch foo {
        case .bar:
            print("")
        }
        """,
      expected: """
        switch foo {
        case .bar:
            print("")
        }
        """)
  }

  @Test func alreadyWrappedUnchanged() {
    assertFormatting(
      WrapCompoundCaseStatements.self,
      input: """
        switch foo {
        case .a,
             .b,
             .c:
            break
        }
        """,
      expected: """
        switch foo {
        case .a,
             .b,
             .c:
            break
        }
        """)
  }

  @Test func defaultCaseUnchanged() {
    assertFormatting(
      WrapCompoundCaseStatements.self,
      input: """
        switch foo {
        default:
            print("")
        }
        """,
      expected: """
        switch foo {
        default:
            print("")
        }
        """)
  }

  @Test func twoCaseItemsWraps() {
    assertFormatting(
      WrapCompoundCaseStatements.self,
      input: """
        switch foo {
        1️⃣case .a, .b:
            break
        }
        """,
      expected: """
        switch foo {
        case .a,
             .b:
            break
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap comma-delimited switch case items onto separate lines")])
  }

  @Test func nestedIndentation() {
    assertFormatting(
      WrapCompoundCaseStatements.self,
      input: """
        func test() {
            switch value {
            1️⃣case .x, .y, .z:
                break
            }
        }
        """,
      expected: """
        func test() {
            switch value {
            case .x,
                 .y,
                 .z:
                break
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap comma-delimited switch case items onto separate lines")])
  }

  @Test func ifAfterSwitchCaseNotWrapped() {
    assertFormatting(
      WrapCompoundCaseStatements.self,
      input: """
        switch foo {
        case "foo":
            print("")
        default:
            print("")
        }
        if let foo = bar, foo != .baz {
            throw error
        }
        """,
      expected: """
        switch foo {
        case "foo":
            print("")
        default:
            print("")
        }
        if let foo = bar, foo != .baz {
            throw error
        }
        """)
  }
}
