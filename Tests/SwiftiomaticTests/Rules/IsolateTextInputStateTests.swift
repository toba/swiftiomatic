import Foundation
import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct IsolateTextInputStateTests: RuleTesting {
    private static func message(_ control: String, _ state: String, _ count: Int) -> String {
        "'\(control)' writes '\(state)' on every keystroke, and this 'body' also builds \(count) views that do not read it. Move the field and its '@State' into their own 'View'"
    }

    private static func stateNote(_ state: String) -> String {
        "The field writes '\(state)' on every keystroke"
    }

    private static func environmentNote(_ value: String, _ state: String) -> String {
        "'\(value)' comes from the environment and feeds work that does not use '\(state)'"
    }

    @Test func guidanceIsShould() { #expect(IsolateTextInputState.guidance == .should) }

    @Test func textFieldBesideUnrelatedSectionsFlagged() {
        assertLint(
            IsolateTextInputState.self,
            """
            struct ProjectSettingsFields: View {
              let project: Project
              2️⃣@State private var draftName = ""
              @State private var saveError: String?

              var body: some View {
                Form {
                  Section {
                    1️⃣TextField("Project name", text: $draftName)
                      .onSubmit(commitName)
                    if draftName.isEmpty { Text("Required") }
                  }
                  SaveErrorSection(message: saveError)
                  LocalFolderSection(localPath: project.localPath)
                  GitHubSection(repo: project.repoFullName)
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("TextField", "draftName", 3),
                    notes: [NoteSpec("2️⃣", message: Self.stateNote("draftName"))]
                )
            ]
        )
    }

    @Test func sliderBesideUnrelatedSectionsFlagged() {
        assertLint(
            IsolateTextInputState.self,
            """
            struct PlayerSettings: View {
              2️⃣@State private var volume = 0.5

              var body: some View {
                Form {
                  1️⃣Slider(value: $volume, in: 0...1)
                  OutputSection()
                  LibrarySection()
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message:
                        "'Slider' writes 'volume' on every change, and this 'body' also builds 2 views that do not read it. Move the slider and its '@State' into their own 'View'",
                    notes: [NoteSpec("2️⃣", message: "The slider writes 'volume' on every change")]
                )
            ]
        )
    }

    @Test func isolatedFieldAndBindingNotFlagged() {
        assertLint(
            IsolateTextInputState.self,
            """
            struct ProjectNameSection: View {
              @State private var draftName = ""

              var body: some View {
                Section {
                  TextField("Project name", text: $draftName)
                  if let problem = nameProblem { Text(problem) }
                } header: {
                  Text("Name")
                }
              }
            }

            struct BoundField: View {
              @Binding var text: String

              var body: some View {
                Form {
                  TextField("x", text: $text)
                  SectionA()
                  SectionB()
                }
              }
            }
            """
        )
    }

    private static func environmentMessage(
        _ control: String,
        _ state: String,
        _ value: String
    ) -> String {
        "'\(control)' writes '\(state)' on every keystroke, and this view also reads the environment value '\(value)' for work that does not use it. Move the field and its '@State' into their own 'View'"
    }

    @Test func textFieldInHelperBesideEnvironmentWorkFlagged() {
        assertLint(
            IsolateTextInputState.self,
            """
            struct OutlineRowView: View {
              let row: OutlineRow
              2️⃣@Environment(\\.editorTheme) private var theme
              @State private var editing = false
              3️⃣@State private var draft = ""

              var body: some View {
                HStack(spacing: 6) {
                  switch row.kind {
                    case let .heading(level): heading(level: level)
                    case .prose: Text(row.text)
                  }
                  Spacer(minLength: 0)
                }
                .onTapGesture(count: 2) { beginEditing() }
              }

              @ViewBuilder private func heading(level: Int) -> some View {
                if editing {
                  1️⃣TextField(text: $draft, label: {})
                    .font(headingFont(level))
                } else {
                  Text(row.text).font(headingFont(level))
                }
              }

              private func headingFont(_ level: Int) -> Font {
                .custom(theme.selected.fontName, size: 18 - Double(level))
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.environmentMessage("TextField", "draft", "theme"),
                    notes: [
                        NoteSpec("3️⃣", message: Self.stateNote("draft")),
                        NoteSpec("2️⃣", message: Self.environmentNote("theme", "draft")),
                    ]
                )
            ]
        )
    }

    @Test func environmentOnlyInActionsOrWithStateNotFlagged() {
        assertLint(
            IsolateTextInputState.self,
            """
            struct RenameSheet: View {
              @Environment(\\.dismiss) private var dismiss
              @Environment(\\.editorTheme) private var theme
              @State private var draft = ""

              var body: some View {
                VStack {
                  TextField("Name", text: $draft)
                    .font(theme.font)
                  Button("Cancel") { dismiss() }
                }
                .onSubmit { close() }
              }

              private func close() { dismiss() }
            }
            """
        )
    }

    @Test func environmentInTaskOrDragClosuresNotFlagged() {
        assertLint(
            IsolateTextInputState.self,
            """
            struct SearchPane: View {
              @Environment(\\.dismiss) private var dismiss
              @Environment(\\.editorTheme) private var theme
              @State private var query = ""

              var body: some View {
                VStack {
                  TextField("Search", text: $query)
                  ResultsList(query: query)
                }
                .dropDestination(for: URL.self) { urls, _ in close() }
                .draggable(query) { preview }
                .background(startWatcher())
              }

              private func startWatcher() -> some View {
                Task.detached { await close() }
                Task.immediate { await close() }
                return Color.clear
              }

              private var preview: some View { Text(theme.name) }

              private func close() { dismiss() }
            }
            """
        )
    }

    @Test func everyEnvironmentValueOfUnrelatedWorkNoted() {
        assertLint(
            IsolateTextInputState.self,
            """
            private struct ProjectNameSection: View {
              2️⃣@Environment(\\.userID) private var userID
              3️⃣@Environment(\\.database) private var database
              @FocusState private var editingName: Bool

              let projectID: Project.ID
              let storedName: String
              @Binding var saveError: String?

              4️⃣@State private var draftName = ""
              @State private var takenNames: Set<String> = []

              private var nameProblem: NameRule.Problem? {
                NameRule.project.problem(with: draftName, taken: takenNames)
              }

              private var writer: JigWriter {
                .init(database: database, userID: userID, error: $saveError)
              }

              var body: some View {
                Section {
                  1️⃣TextField("Project name", text: $draftName)
                    .focused($editingName)
                    .onSubmit(commitName)
                  if let problem = nameProblem {
                    Text(NameRule.project.message(for: problem))
                  }
                } header: {
                  Text("Name")
                }
              }

              private func commitName() {
                guard nameProblem == nil else { return }
                let name = NameRule.normalized(draftName)
                draftName = name
                if !writer({ try $0.updateProject(projectID.uuidString, name: name) }) {
                  draftName = storedName
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.environmentMessage("TextField", "draftName", "database"),
                    notes: [
                        NoteSpec("4️⃣", message: Self.stateNote("draftName")),
                        NoteSpec("3️⃣", message: Self.environmentNote("database", "draftName")),
                        NoteSpec("2️⃣", message: Self.environmentNote("userID", "draftName")),
                    ]
                )
            ]
        )
    }

    @Test func discreteControlBesideEnvironmentWorkNotFlagged() {
        assertLint(
            IsolateTextInputState.self,
            """
            struct PinSection: View {
              @Environment(\\.database) private var database
              @State private var pinned = false

              private var summary: String { database.summary() }

              var body: some View {
                Section {
                  Toggle("Pinned", isOn: $pinned)
                  Text(summary)
                  Text("Other")
                  Text("More")
                }
              }
            }
            """
        )
    }
}
