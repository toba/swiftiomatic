@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantViewBuilderTests: RuleTesting {
  @Test func singleExpressionComputedProperty() {
    assertFormatting(
      DropRedundantViewBuilder.self,
      input: """
        struct MyView: View {
          1️⃣@ViewBuilder
          var body: some View {
            Text("hello")
          }
        }
        """,
      expected: """
        struct MyView: View {
          var body: some View {
            Text("hello")
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove '@ViewBuilder'; single-expression body does not need a result builder"),
      ]
    )
  }

  @Test func singleExpressionFunction() {
    assertFormatting(
      DropRedundantViewBuilder.self,
      input: """
        1️⃣@ViewBuilder
        func makeContent() -> some View {
          Text("hello")
        }
        """,
      expected: """
        func makeContent() -> some View {
          Text("hello")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove '@ViewBuilder'; single-expression body does not need a result builder"),
      ]
    )
  }

  @Test func multiExpressionNotFlagged() {
    assertFormatting(
      DropRedundantViewBuilder.self,
      input: """
        @ViewBuilder
        var body: some View {
          Text("hello")
          Text("world")
        }
        """,
      expected: """
        @ViewBuilder
        var body: some View {
          Text("hello")
          Text("world")
        }
        """,
      findings: []
    )
  }

  @Test func ifElseNotFlagged() {
    assertFormatting(
      DropRedundantViewBuilder.self,
      input: """
        @ViewBuilder
        func content() -> some View {
          if condition {
            Text("yes")
          } else {
            Text("no")
          }
        }
        """,
      expected: """
        @ViewBuilder
        func content() -> some View {
          if condition {
            Text("yes")
          } else {
            Text("no")
          }
        }
        """,
      findings: []
    )
  }

  @Test func noViewBuilderNotFlagged() {
    assertFormatting(
      DropRedundantViewBuilder.self,
      input: """
        var body: some View {
          Text("hello")
        }
        """,
      expected: """
        var body: some View {
          Text("hello")
        }
        """,
      findings: []
    )
  }

  @Test func protocolRequirementNotFlagged() {
    assertFormatting(
      DropRedundantViewBuilder.self,
      input: """
        protocol MyProtocol {
          @ViewBuilder
          func makeContent() -> some View
        }
        """,
      expected: """
        protocol MyProtocol {
          @ViewBuilder
          func makeContent() -> some View
        }
        """,
      findings: []
    )
  }

  @Test func storedPropertyNotFlagged() {
    assertFormatting(
      DropRedundantViewBuilder.self,
      input: """
        @ViewBuilder var content: () -> some View
        """,
      expected: """
        @ViewBuilder var content: () -> some View
        """,
      findings: []
    )
  }

  @Test func viewBuilderOnSameLineAsFunc() {
    assertFormatting(
      DropRedundantViewBuilder.self,
      input: """
        1️⃣@ViewBuilder func makeContent() -> some View {
          Text("hello")
        }
        """,
      expected: """
        func makeContent() -> some View {
          Text("hello")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove '@ViewBuilder'; single-expression body does not need a result builder"),
      ]
    )
  }
}
