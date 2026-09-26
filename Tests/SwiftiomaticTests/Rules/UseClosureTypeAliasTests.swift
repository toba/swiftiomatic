@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseClosureTypeAliasTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'\(name)' spells out a complex closure type. Name it with a 'typealias' so the declaration reads at a glance"
  }

  @Test func guidanceIsConsider() {
    #expect(UseClosureTypeAlias.guidance == .consider)
  }

  @Test func complexClosureTypesFlagged() {
    assertLint(
      UseClosureTypeAlias.self,
      """
      struct ProjectItemList<Item, Editor: View, Add: View, Summary: View>: View {
        1️⃣@ViewBuilder let editor: (Item?, Binding<Bool>) -> Editor
        2️⃣@ViewBuilder let add: (@escaping () -> Void) -> Add
        @ViewBuilder let summary: (Item) -> Summary
        3️⃣var handler: ((Int) -> (String) -> Void)?
        let delete: (Item) -> Void
        let completion: (Result<Data, Error>) -> Void

        var body: some View { Text("x") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("editor")),
        FindingSpec("2️⃣", message: Self.message("add")),
        FindingSpec("3️⃣", message: Self.message("handler")),
      ]
    )
  }

  @Test func localsParametersAndComputedNotFlagged() {
    assertLint(
      UseClosureTypeAlias.self,
      """
      struct Box {
        var action: ((@escaping () -> Void) -> Void) { { $0() } }

        func run(_ body: (@escaping () -> Void) -> Void) {
          let local: (@escaping () -> Void) -> Void = body
          local {}
        }
      }
      """
    )
  }
}
