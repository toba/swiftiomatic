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
}
