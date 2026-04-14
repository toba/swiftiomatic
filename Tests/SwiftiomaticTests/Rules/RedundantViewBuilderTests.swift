@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantViewBuilderTests: RuleTesting {
  @Test func singleExpressionComputedProperty() {
    assertLint(
      RedundantViewBuilder.self,
      """
      struct MyView: View {
        1️⃣@ViewBuilder
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
    assertLint(
      RedundantViewBuilder.self,
      """
      1️⃣@ViewBuilder
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
    assertLint(
      RedundantViewBuilder.self,
      """
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
    assertLint(
      RedundantViewBuilder.self,
      """
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
    assertLint(
      RedundantViewBuilder.self,
      """
      var body: some View {
        Text("hello")
      }
      """,
      findings: []
    )
  }

  @Test func protocolRequirementNotFlagged() {
    assertLint(
      RedundantViewBuilder.self,
      """
      protocol MyProtocol {
        @ViewBuilder
        func makeContent() -> some View
      }
      """,
      findings: []
    )
  }

  @Test func storedPropertyNotFlagged() {
    assertLint(
      RedundantViewBuilder.self,
      """
      @ViewBuilder var content: () -> some View
      """,
      findings: []
    )
  }
}
