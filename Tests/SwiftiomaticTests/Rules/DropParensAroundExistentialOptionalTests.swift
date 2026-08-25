@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropParensAroundExistentialOptionalTests: RuleTesting {
  private static let message =
    "remove the parentheses; 'any P?' and 'some P?' parse without them since SE-0521"

  @Test func anyOptionalUnwrapped() {
    assertFormatting(
      DropParensAroundExistentialOptional.self,
      input: """
        func find() -> 1️⃣(any Shape)? { nil }
        """,
      expected: """
        func find() -> any Shape? { nil }
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func someOptionalUnwrapped() {
    assertFormatting(
      DropParensAroundExistentialOptional.self,
      input: """
        func find() -> 1️⃣(some Shape)? { nil }
        """,
      expected: """
        func find() -> some Shape? { nil }
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func implicitlyUnwrappedFormUnwrapped() {
    assertFormatting(
      DropParensAroundExistentialOptional.self,
      input: """
        var shape: 1️⃣(any Shape)!
        """,
      expected: """
        var shape: any Shape!
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func parameterTypeUnwrapped() {
    assertFormatting(
      DropParensAroundExistentialOptional.self,
      input: """
        func draw(_ shape: 1️⃣(any Shape)?) {}
        """,
      expected: """
        func draw(_ shape: any Shape?) {}
        """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func bareFormLeftAlone() {
    assertFormatting(
      DropParensAroundExistentialOptional.self,
      input: """
        func find() -> any Shape? { nil }
        """,
      expected: """
        func find() -> any Shape? { nil }
        """,
      findings: []
    )
  }

  @Test func metatypeParensLeftAlone() {
    assertFormatting(
      DropParensAroundExistentialOptional.self,
      input: """
        func find() -> (any Shape).Type? { nil }
        """,
      expected: """
        func find() -> (any Shape).Type? { nil }
        """,
      findings: []
    )
  }

  @Test func plainTupleLeftAlone() {
    assertFormatting(
      DropParensAroundExistentialOptional.self,
      input: """
        func find() -> (Int, String)? { nil }
        """,
      expected: """
        func find() -> (Int, String)? { nil }
        """,
      findings: []
    )
  }

  @Test func labelledSingleElementTupleLeftAlone() {
    assertFormatting(
      DropParensAroundExistentialOptional.self,
      input: """
        func find() -> (shape: any Shape)? { nil }
        """,
      expected: """
        func find() -> (shape: any Shape)? { nil }
        """,
      findings: []
    )
  }

  @Test func nonExistentialSingleElementLeftAlone() {
    assertFormatting(
      DropParensAroundExistentialOptional.self,
      input: """
        func find() -> (Int)? { nil }
        """,
      expected: """
        func find() -> (Int)? { nil }
        """,
      findings: []
    )
  }
}
