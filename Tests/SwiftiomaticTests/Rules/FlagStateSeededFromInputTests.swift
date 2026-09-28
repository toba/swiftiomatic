import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct FlagStateSeededFromInputTests: RuleTesting {
    private static func message(_ state: String, _ input: String) -> String {
        "'\(state)' seeds '@State' from the input '\(input)'. The state keeps its first value when the parent passes a new one. Give each new input a new view identity, or keep the value in the parent"
    }

    private static func declarationMessage(
        _ state: String,
        _ input: String,
        wrapper: String = "State"
    ) -> String {
        "'@\(wrapper)' property '\(state)' takes its first value from the initializer input '\(input)'. A later value of the input does not reach it. Update it in 'onChange(of:initial: true)' or 'task(id:)', or name the input as initial only"
    }

    private static func ownerMessage(_ owner: String) -> String {
        "'\(owner)' seeds view state from initializer inputs. That state does not follow later input values"
    }

    private static func objectMessage(_ state: String, _ input: String) -> String {
        "'\(state)' seeds '@StateObject' from the input '\(input)'. The state keeps its first value when the parent passes a new one. Give each new input a new view identity, or keep the value in the parent"
    }

    @Test func guidanceIsShouldNot() { #expect(FlagStateSeededFromInput.guidance == .shouldNot) }

    @Test func stateSeededFromParameterFlagged() {
        assertLint(
            FlagStateSeededFromInput.self,
            """
            struct 0️⃣EditableText: View {
              let prompt: String
              4️⃣@State private var draft: String
              5️⃣@State private var name: String
              6️⃣@State private var noRepo: Bool

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
                FindingSpec("0️⃣", message: Self.ownerMessage("EditableText")),
                FindingSpec("4️⃣", message: Self.declarationMessage("draft", "seed")),
                FindingSpec("5️⃣", message: Self.declarationMessage("name", "folder")),
                FindingSpec("6️⃣", message: Self.declarationMessage("noRepo", "folder")),
            ]
        )
    }

    @Test func plainAssignmentToStateFlagged() {
        // From Thesis `EditorThemeStyleView` and `OutlineList`.
        assertLint(
            FlagStateSeededFromInput.self,
            """
            struct 3️⃣EditorThemeStyleView: View {
              @Binding var style: EditorThemeStyle
              4️⃣@State private var baseFontSize: Double
              private let editable: Bool

              init(_ style: Binding<EditorThemeStyle>, font: PlatformFont, editable: Bool = false) {
                _style = style
                self.editable = editable
                1️⃣baseFontSize = font.pointSize
              }

              var body: some View { Text("\\(baseFontSize)") }
            }

            struct 5️⃣OutlineList<Data: RecursiveCollection, RowContent: View>: View {
              let data: Data
              6️⃣@State private var onMove: MoveRowHandler?
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
                FindingSpec("3️⃣", message: Self.ownerMessage("EditorThemeStyleView")),
                FindingSpec("4️⃣", message: Self.declarationMessage("baseFontSize", "font")),
                FindingSpec("5️⃣", message: Self.ownerMessage("OutlineList")),
                FindingSpec("6️⃣", message: Self.declarationMessage("onMove", "onMove")),
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

    @Test func projectComposerStateDeclarationsFlagged() {
        // From jig `ProjectComposer`: SwiftFairy reports the owner and each seeded declaration.
        assertLint(
            FlagStateSeededFromInput.self,
            """
            struct 0️⃣ProjectComposer: View {
              @Environment(\\.dismiss) private var dismiss
              let onCreate: (Project) -> Void

              1️⃣@State private var name: String
              @State private var detail = ""
              2️⃣@State private var detectedRepo: GitHubRepository?
              @State private var pickingFolder = false
              3️⃣@State private var noRepoFound: Bool
              /// The folder the project maps to.
              4️⃣@State private var pickedFolder: URL
              @State private var legacy: Findings?
              /// The name the current folder suggested.
              5️⃣@State private var derivedName: String

              init(draft: ProjectFolderDraft, onCreate: @escaping (Project) -> Void) {
                self.onCreate = onCreate
                6️⃣_name = State(initialValue: draft.name)
                7️⃣_derivedName = State(initialValue: draft.name)
                8️⃣_detectedRepo = State(initialValue: draft.repo)
                9️⃣_noRepoFound = State(initialValue: draft.repo == nil)
                🔟_pickedFolder = State(initialValue: draft.folder)
              }

              var body: some View { Text(name) }
            }
            """,
            findings: [
                FindingSpec("0️⃣", message: Self.ownerMessage("ProjectComposer")),
                FindingSpec("1️⃣", message: Self.declarationMessage("name", "draft")),
                FindingSpec("2️⃣", message: Self.declarationMessage("detectedRepo", "draft")),
                FindingSpec("3️⃣", message: Self.declarationMessage("noRepoFound", "draft")),
                FindingSpec("4️⃣", message: Self.declarationMessage("pickedFolder", "draft")),
                FindingSpec("5️⃣", message: Self.declarationMessage("derivedName", "draft")),
                FindingSpec("6️⃣", message: Self.message("name", "draft")),
                FindingSpec("7️⃣", message: Self.message("derivedName", "draft")),
                FindingSpec("8️⃣", message: Self.message("detectedRepo", "draft")),
                FindingSpec("9️⃣", message: Self.message("noRepoFound", "draft")),
                FindingSpec("🔟", message: Self.message("pickedFolder", "draft")),
            ]
        )
    }

    @Test func stateObjectSeededFromInputFlagged() {
        assertLint(
            FlagStateSeededFromInput.self,
            """
            struct 0️⃣SpeciesProfile: View {
              let speciesID: String
              1️⃣@StateObject private var model: SpeciesModel

              init(speciesID: String) {
                self.speciesID = speciesID
                2️⃣_model = StateObject(wrappedValue: SpeciesModel(id: speciesID))
              }

              var body: some View { Text(speciesID) }
            }
            """,
            findings: [
                FindingSpec("0️⃣", message: Self.ownerMessage("SpeciesProfile")),
                FindingSpec(
                    "1️⃣",
                    message: Self.declarationMessage("model", "speciesID", wrapper: "StateObject")),
                FindingSpec("2️⃣", message: Self.objectMessage("model", "speciesID")),
            ]
        )
    }

    @Test func ownerReportedForInitializerInExtension() {
        assertLint(
            FlagStateSeededFromInput.self,
            """
            struct 0️⃣Counter: View {
              1️⃣@State private var count: Int

              var body: some View { Text("Count") }
            }

            extension Counter {
              init(start: Int) {
                2️⃣_count = State(initialValue: start)
              }
            }
            """,
            findings: [
                FindingSpec("2️⃣", message: Self.message("count", "start")),
                FindingSpec("0️⃣", message: Self.ownerMessage("Counter")),
                FindingSpec("1️⃣", message: Self.declarationMessage("count", "start")),
            ]
        )
    }

    @Test func initialOnlyInputNotFlagged() {
        // An input named as initial only states the contract, so the copy is intended.
        assertLint(
            FlagStateSeededFromInput.self,
            """
            struct Disclosure: View {
              @State private var isExpanded: Bool
              @State private var text: String

              init(initiallyExpanded: Bool, initialText: String) {
                _isExpanded = State(initialValue: initiallyExpanded)
                text = initialText
              }

              var body: some View { Text(text) }
            }
            """
        )
    }

    @Test func stateCreatedInTaskNotFlagged() {
        assertLint(
            FlagStateSeededFromInput.self,
            """
            struct AnimalDetail: View {
              let animalID: UUID
              @State private var viewModel: AnimalDetailViewModel?

              var body: some View {
                Text(viewModel?.description ?? "")
                  .task(id: animalID) { viewModel = AnimalDetailViewModel(id: animalID) }
              }
            }
            """
        )
    }
}
