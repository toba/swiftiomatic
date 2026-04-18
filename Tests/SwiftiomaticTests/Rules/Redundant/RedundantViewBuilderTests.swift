@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantViewBuilderTests: RuleTesting {
  @Test func singleExpressionComputedProperty() {
    assertFormatting(
      RedundantViewBuilder.self,
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
      RedundantViewBuilder.self,
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
      RedundantViewBuilder.self,
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
      RedundantViewBuilder.self,
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
      RedundantViewBuilder.self,
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
      RedundantViewBuilder.self,
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
      RedundantViewBuilder.self,
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
      RedundantViewBuilder.self,
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
