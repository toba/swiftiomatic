@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoAnyViewInForEachTests: RuleTesting {
  private static let message =
    "'AnyView' inside 'ForEach' erases row identity and forces extra invalidation — extract a '@ViewBuilder' helper or use 'Group' with 'if'/'switch'"

  @Test func directAnyViewFlagged() {
    assertLint(
      NoAnyViewInForEach.self,
      """
      ForEach(items) { item in
        1️⃣AnyView(Text(item.name))
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func anyViewInIfBranchFlagged() {
    assertLint(
      NoAnyViewInForEach.self,
      """
      ForEach(items) { item in
        if item.isHighlighted {
          1️⃣AnyView(Text(item.name).bold())
        } else {
          2️⃣AnyView(Text(item.name))
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message),
        FindingSpec("2️⃣", message: Self.message),
      ]
    )
  }

  @Test func anyViewInNestedClosureFlagged() {
    assertLint(
      NoAnyViewInForEach.self,
      """
      ForEach(items) { item in
        Button(action: {}) {
          1️⃣AnyView(Text(item.name))
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }

  @Test func anyViewOutsideForEachNotFlagged() {
    assertLint(
      NoAnyViewInForEach.self,
      """
      var body: some View {
        AnyView(Text("hi"))
      }
      """,
      findings: []
    )
  }

  @Test func plainForEachNotFlagged() {
    assertLint(
      NoAnyViewInForEach.self,
      """
      ForEach(items) { item in
        Text(item.name)
      }
      """,
      findings: []
    )
  }

  @Test func anyViewBeforeForEachNotFlagged() {
    assertLint(
      NoAnyViewInForEach.self,
      """
      func make() -> AnyView {
        AnyView(Text("hi"))
      }

      var body: some View {
        ForEach(items) { item in
          Text(item.name)
        }
      }
      """,
      findings: []
    )
  }

  @Test func nestedForEachInnerAnyViewFlagged() {
    assertLint(
      NoAnyViewInForEach.self,
      """
      ForEach(sections) { section in
        ForEach(section.items) { item in
          1️⃣AnyView(Text(item.name))
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message)]
    )
  }
}
