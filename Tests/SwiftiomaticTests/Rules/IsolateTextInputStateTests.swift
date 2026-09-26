@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct IsolateTextInputStateTests: RuleTesting {
  private static func message(_ control: String, _ state: String, _ count: Int) -> String {
    "'\(control)' writes '\(state)' on every keystroke, and this 'body' also builds \(count) views that do not read it. Move the field and its '@State' into their own 'View'"
  }

  @Test func textFieldBesideUnrelatedSectionsFlagged() {
    assertLint(
      IsolateTextInputState.self,
      """
      struct ProjectSettingsFields: View {
        let project: Project
        @State private var draftName = ""
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
      findings: [FindingSpec("1️⃣", message: Self.message("TextField", "draftName", 3))]
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

  private static func environmentMessage(_ control: String, _ state: String, _ value: String)
    -> String
  {
    "'\(control)' writes '\(state)' on every keystroke, and this view also reads the environment value '\(value)' for work that does not use it. Move the field and its '@State' into their own 'View'"
  }

  @Test func textFieldInHelperBesideEnvironmentWorkFlagged() {
    assertLint(
      IsolateTextInputState.self,
      """
      struct OutlineRowView: View {
        let row: OutlineRow
        @Environment(\\.editorTheme) private var theme
        @State private var editing = false
        @State private var draft = ""

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
        FindingSpec("1️⃣", message: Self.environmentMessage("TextField", "draft", "theme"))
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
}
