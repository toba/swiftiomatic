@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagStateSeededFromInputTests: RuleTesting {
  private static func message(_ state: String, _ input: String) -> String {
    "'\(state)' seeds '@State' from the input '\(input)'. The state keeps its first value when the parent passes a new one. Give each new input a new view identity, or keep the value in the parent"
  }

  @Test func guidanceIsConsider() {
    #expect(FlagStateSeededFromInput.guidance == .consider)
  }

  @Test func stateSeededFromParameterFlagged() {
    assertLint(
      FlagStateSeededFromInput.self,
      """
      struct EditableText: View {
        let prompt: String
        @State private var draft: String
        @State private var name: String
        @State private var noRepo: Bool

        init(prompt: String, seed: String = "", draft folder: FolderDraft) {
          self.prompt = prompt
          1️⃣_draft = State(initialValue: seed)
          2️⃣self._name = State(wrappedValue: folder.name)
          3️⃣_noRepo = State(initialValue: folder.repo == nil)
        }

        var body: some View { TextField(prompt, text: $draft) }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("draft", "seed")),
        FindingSpec("2️⃣", message: Self.message("name", "folder")),
        FindingSpec("3️⃣", message: Self.message("noRepo", "folder")),
      ]
    )
  }

  @Test func plainAssignmentToStateFlagged() {
    // From Thesis `EditorThemeStyleView` and `OutlineList`.
    assertLint(
      FlagStateSeededFromInput.self,
      """
      struct EditorThemeStyleView: View {
        @Binding var style: EditorThemeStyle
        @State private var baseFontSize: Double
        private let editable: Bool

        init(_ style: Binding<EditorThemeStyle>, font: PlatformFont, editable: Bool = false) {
          _style = style
          self.editable = editable
          1️⃣baseFontSize = font.pointSize
        }

        var body: some View { Text("\\(baseFontSize)") }
      }

      struct OutlineList<Data: RecursiveCollection, RowContent: View>: View {
        let data: Data
        @State private var onMove: MoveRowHandler?
        @State private var draggingID: Data.Element.ID?

        init(_ data: Data, onMove: MoveRowHandler? = nil) {
          self.data = data
          2️⃣self.onMove = onMove
          draggingID = nil
        }

        var body: some View { Text("x") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("baseFontSize", "font")),
        FindingSpec("2️⃣", message: Self.message("onMove", "onMove")),
      ]
    )
  }

  @Test func plainAssignmentToNonStateNotFlagged() {
    assertLint(
      FlagStateSeededFromInput.self,
      """
      struct Row: View {
        let title: String
        @Binding var isOn: Bool
        @State private var count = 0

        init(title: String, isOn: Binding<Bool>) {
          self.title = title
          _isOn = isOn
          count = 0
        }

        var body: some View { Text(title) }
      }
      """
    )
  }

  @Test func constantSeedAndNonViewNotFlagged() {
    assertLint(
      FlagStateSeededFromInput.self,
      """
      struct Counter: View {
        @State private var count: Int
        @Binding var isOn: Bool

        init(isOn: Binding<Bool>) {
          _isOn = isOn
          _count = State(initialValue: 0)
        }

        var body: some View { Text("\\(count)") }
      }

      struct Model {
        var state: State<Int>
        init(start: Int) { state = State(initialValue: start) }
      }
      """
    )
  }
}
