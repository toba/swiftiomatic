import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoDynamicPropertyInViewInitializerTests: RuleTesting {
    private static func message(_ name: String, _ wrapper: String) -> String {
        "'\(name)' is a '@\(wrapper)' property. The initializer uses it before SwiftUI installs its storage, so it sees a default value and loses any change. Move the work to 'body', 'task(id:)' or the parent"
    }

    @Test func guidanceIsShould() {
        #expect(NoDynamicPropertyInViewInitializer.guidance == .should)
    }

    @Test func citationViewUpdatesStateInInitFlagged() {
        // From Thesis `CitationView`: the view conforms to a protocol declared in another file.
        assertLint(
            NoDynamicPropertyInViewInitializer.self,
            """
            struct CitationView: InTextCitationPopover {
              @Dependency(\\.defaultDatabase) private var sqlite
              @Environment(\\.editorTheme) private var theme
              @State private var citations = Citation.ViewModel(for: .main)

              init(
                id groupID: Node.ID,
                within: Node.ID,
                at characterIndex: Int,
                isEditing: Bool,
                dismiss: @escaping () -> Void,
              ) {
                1️⃣citations.update(
                  group: groupID,
                  within: within,
                  at: characterIndex,
                  isEditing: isEditing,
                  dismiss: dismiss,
                )
              }

              init(edit group: SelectedCitationGroup, dismiss: @escaping () -> Void) {
                2️⃣self.citations.update(selection: group, dismiss: dismiss)
              }

              var body: some View { Text("x") }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("citations", "State")),
                FindingSpec("2️⃣", message: Self.message("citations", "State")),
            ]
        )
    }

    @Test func readsOfOtherDynamicPropertiesFlagged() {
        assertLint(
            NoDynamicPropertyInViewInitializer.self,
            """
            struct Editor: View {
              @Environment(\\.editorTheme) private var theme
              @Binding var isOn: Bool
              @FocusState private var focused: Bool
              @State private var count = 0
              private let tint: Color
              private let label: String

              init(isOn: Binding<Bool>) {
                _isOn = isOn
                tint = 1️⃣theme.accent
                label = 2️⃣self.isOn ? "On" : "Off"
                3️⃣focused = true
                4️⃣count += 1
                6️⃣count = 2
                let binding = 5️⃣$count
                print(binding)
              }

              var body: some View { Text(label) }
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: Self.message("theme", "Environment")),
                FindingSpec("2️⃣", message: Self.message("isOn", "Binding")),
                FindingSpec("3️⃣", message: Self.message("focused", "FocusState")),
                FindingSpec("4️⃣", message: Self.message("count", "State")),
                FindingSpec("6️⃣", message: Self.message("count", "State")),
                FindingSpec("5️⃣", message: Self.message("count", "State")),
            ]
        )
    }

    @Test func initializationAndShadowedNamesNotFlagged() {
        assertLint(
            NoDynamicPropertyInViewInitializer.self,
            """
            struct OutlineList: View {
              @State private var onMove: MoveRowHandler?
              @State private var baseFontSize: Double
              @Binding var selection: Int?
              @Environment(\\.theme) private var theme
              let rows: [Row]

              init(rows: [Row], selection: Binding<Int?>, onMove: MoveRowHandler? = nil, font: PlatformFont) {
                self.rows = rows
                _selection = selection
                self.onMove = onMove
                baseFontSize = font.pointSize
                _theme = Environment(\\.theme)
                let theme = Theme.default
                print(theme, rows.map { row in row.theme })
              }

              var body: some View { Text("x") }
            }

            struct Model {
              var count = 0
              init() { count += 1 }
            }
            """,
            findings: []
        )
    }
}
