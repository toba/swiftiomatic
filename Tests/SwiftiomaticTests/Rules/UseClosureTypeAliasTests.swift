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

  private static func repeatedMessage(_ name: String, _ type: String) -> String {
    "'\(name)' repeats the closure type '\(type)', which this file spells more than once. Name it with a 'typealias'"
  }

  @Test func repeatedParameterListFlagged() {
    // From Thesis `OutlineList.swift`
    assertLint(
      UseClosureTypeAlias.self,
      """
      struct OutlineDrag<ID: Hashable> {
        1️⃣let canDrop: (_ dragged: ID, _ edge: OutlineDropEdge, _ target: ID) -> Bool
        2️⃣let onDrop: (_ dragged: ID, _ edge: OutlineDropEdge, _ target: ID) -> Void
        let draggingID: Binding<ID?>
        3️⃣var nestTarget: ((_ dragged: ID, _ edge: OutlineDropEdge, _ target: ID) -> ID?)?
        var canDrag: ((_ id: ID) -> Bool)?
      }

      struct OutlineList<Data: RecursiveCollection, RowContent: View>: View {
        private let onMove: MoveRowHandler?
        4️⃣private let onCanDrop: ((Data.Element.ID, OutlineDropEdge, Data.Element.ID) -> Bool)?
        5️⃣private let onPerformDrop: ((Data.Element.ID, OutlineDropEdge, Data.Element.ID) -> Void)?
        @ViewBuilder let rowContent: (Data.Element, Bool) -> RowContent

        init(
          _ data: Data,
          onMove: MoveRowHandler? = nil,
          6️⃣canDrop: ((Data.Element.ID, OutlineDropEdge, Data.Element.ID) -> Bool)? = nil,
          7️⃣onDrop: ((Data.Element.ID, OutlineDropEdge, Data.Element.ID) -> Void)? = nil,
          rowContent: @escaping (Data.Element, Bool) -> RowContent,
        ) {}

        var body: some View { Text("x") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.repeatedMessage("canDrop", "(ID, OutlineDropEdge, ID) -> Bool")),
        FindingSpec("2️⃣", message: Self.repeatedMessage("onDrop", "(ID, OutlineDropEdge, ID) -> Void")),
        FindingSpec("3️⃣", message: Self.message("nestTarget")),
        FindingSpec(
          "4️⃣",
          message: Self.repeatedMessage(
            "onCanDrop", "(Data.Element.ID, OutlineDropEdge, Data.Element.ID) -> Bool")),
        FindingSpec(
          "5️⃣",
          message: Self.repeatedMessage(
            "onPerformDrop", "(Data.Element.ID, OutlineDropEdge, Data.Element.ID) -> Void")),
        FindingSpec(
          "6️⃣",
          message: Self.repeatedMessage(
            "canDrop", "(Data.Element.ID, OutlineDropEdge, Data.Element.ID) -> Bool")),
        FindingSpec(
          "7️⃣",
          message: Self.repeatedMessage(
            "onDrop", "(Data.Element.ID, OutlineDropEdge, Data.Element.ID) -> Void")),
      ]
    )
  }

  @Test func repeatedWholeTypeFlagged() {
    // From Thesis `ProjectTree.swift`
    assertLint(
      UseClosureTypeAlias.self,
      """
      struct ProjectTree: View {
        var createFolder: (ProjectFolder.ID?) -> Void
        var deleteFolder: (ProjectFolder.ID) -> Void
        1️⃣var delete: (NodeMenuItem) -> Void
        var requestImport: (NodeMenuItem, LocalFile.Importable) -> Void
        2️⃣var restore: (NodeMenuItem) -> Void
        3️⃣var permanentlyDelete: (NodeMenuItem) -> Void
        var emptyTrash: () -> Void
        var reset: () -> Void

        var body: some View { Text("x") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.repeatedMessage("delete", "(NodeMenuItem) -> Void")),
        FindingSpec("2️⃣", message: Self.repeatedMessage("restore", "(NodeMenuItem) -> Void")),
        FindingSpec(
          "3️⃣", message: Self.repeatedMessage("permanentlyDelete", "(NodeMenuItem) -> Void")),
      ]
    )
  }
  private static func shapeMessage(_ name: String, _ shape: String) -> String {
    "'\(name)' shares the closure shape '\(shape)' with another declaration in this file. Name the shape with a generic 'typealias'"
  }

  @Test func closureTypesDifferingInOneParameterFlagged() {
    // From Thesis `ProjectTreeRow.swift`
    assertLint(
      UseClosureTypeAlias.self,
      """
      struct ProjectTreeRow: View {
        let createFolder: (ProjectFolder.ID?) -> Void
        let deleteFolder: (ProjectFolder.ID) -> Void
        let delete: (NodeMenuItem) -> Void
        1️⃣let requestImport: (NodeMenuItem, LocalFile.Importable) -> Void
        2️⃣let export: (NodeMenuItem, LocalFile.Exportable) -> Void
        let move: (Int, String) -> Bool

        var body: some View { Text("x") }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: Self.shapeMessage("requestImport", "(NodeMenuItem, _) -> Void")),
        FindingSpec("2️⃣", message: Self.shapeMessage("export", "(NodeMenuItem, _) -> Void")),
      ]
    )
  }

  @Test func heavilyDecoratedClosureParameterFlagged() {
    // From Thesis `ProjectNodeLabel.swift`
    assertLint(
      UseClosureTypeAlias.self,
      """
      struct ProjectNodeLabel: View {
        var body: some View { Text("x") }

        private func addDivision(
          _ division: LocalizedStringResource,
          1️⃣_ insert: @escaping @Sendable (TobaData::Transaction) throws -> Node.ID,
        ) {}

        private func run(_ body: @escaping @Sendable () -> Void) {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("insert")),
      ]
    )
  }

  @Test func initParameterSettingStoredClosureNotCounted() {
    assertLint(
      UseClosureTypeAlias.self,
      """
      struct ItemRow: View {
        let onSelect: (Item) -> Void

        init(onSelect: @escaping (Item) -> Void) {
          self.onSelect = onSelect
        }

        var body: some View { Text("x") }
      }
      """
    )
  }

  @Test func initParameterWithDifferentInternalNameStillCounted() {
    assertLint(
      UseClosureTypeAlias.self,
      """
      struct ItemRow: View {
        1️⃣let onSelect: (Item) -> Void

        init(2️⃣onSelect handler: @escaping (Item) -> Void) {
          onSelect = handler
        }

        var body: some View { Text("x") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.repeatedMessage("onSelect", "(Item) -> Void")),
        FindingSpec("2️⃣", message: Self.repeatedMessage("handler", "(Item) -> Void")),
      ]
    )
  }
}
