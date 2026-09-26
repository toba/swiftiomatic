import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct OrderViewMembersTests: RuleTesting {
    private static func message(
        _ name: String,
        _ category: String,
        before other: String,
        _ otherCategory: String
    ) -> String { "'\(name)' (\(category)) must come before '\(other)' (\(otherCategory))" }

    private static func note(_ name: String) -> String { "move it above '\(name)'" }

    @Test func correctOrderNotFlagged() {
        assertLint(
            OrderViewMembers.self,
            """
            struct EditorView: View {
              @Environment(\\.dismiss) private var dismiss
              @FocusState private var isFocused: Bool
              let document: Document
              @State private var text = ""
              var count = 0
              private var title: String { document.title }
              init(document: Document) { self.document = document }
              var body: some View { header }
              private var header: some View { Text(title) }
              @ViewBuilder private func row(_ index: Int) -> some View { Text("\\(index)") }
              private func save() {}
            }
            """
        )
    }

    @Test func stateBeforeEnvironmentFlagged() {
        assertLint(
            OrderViewMembers.self,
            """
            struct EditorView: View {
              @State private 2️⃣var text = ""
              @Environment(\\.dismiss) private 1️⃣var dismiss
              var body: some View { Text(text) }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message(
                        "dismiss", "environment property", before: "text", "stored property"),
                    notes: [NoteSpec("2️⃣", message: Self.note("text"))]
                )
            ]
        )
    }

    @Test func functionBeforeBodyFlagged() {
        assertLint(
            OrderViewMembers.self,
            """
            struct EditorView: View {
              let title: String
              private 2️⃣func save() {}
              1️⃣var body: some View { Text(title) }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("body", "body", before: "save", "function"),
                    notes: [NoteSpec("2️⃣", message: Self.note("save"))]
                )
            ]
        )
    }

    @Test func onlyFirstOutOfOrderMemberReported() {
        assertLint(
            OrderViewMembers.self,
            """
            struct EditorView: View {
              2️⃣var body: some View { Text(title) }
              1️⃣init(title: String) { self.title = title }
              let title: String
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("init", "initializer", before: "body", "body"),
                    notes: [NoteSpec("2️⃣", message: Self.note("body"))]
                )
            ]
        )
    }

    @Test func viewBuilderBeforeBodyFlagged() {
        assertLint(
            OrderViewMembers.self,
            """
            struct EditorView: View {
              @ViewBuilder 2️⃣var header: some View { Text("a") }
              1️⃣var body: some View { header }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("body", "body", before: "header", "view builder"),
                    notes: [NoteSpec("2️⃣", message: Self.note("header"))]
                )
            ]
        )
    }

    @Test func computedAfterInitFlagged() {
        assertLint(
            OrderViewMembers.self,
            """
            struct EditorView: View {
              let title: String
              2️⃣init(title: String) { self.title = title }
              private 1️⃣var upper: String { title.uppercased() }
              var body: some View { Text(upper) }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message(
                        "upper", "computed property", before: "init", "initializer"),
                    notes: [NoteSpec("2️⃣", message: Self.note("init"))]
                )
            ]
        )
    }

    @Test func observedStoredVarIsStored() {
        assertLint(
            OrderViewMembers.self,
            """
            struct EditorView: View {
              let title: String
              var count = 0 { didSet { print(count) } }
              var body: some View { Text(title) }
            }
            """
        )
    }

    @Test func staticMembersAndNestedTypesIgnored() {
        assertLint(
            OrderViewMembers.self,
            """
            struct EditorView: View {
              static let padding = 4.0
              enum Mode { case a, b }
              2️⃣var body: some View { Text("a") }
              static func make() -> EditorView { EditorView() }
              @State private 1️⃣var mode = Mode.a
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message("mode", "stored property", before: "body", "body"),
                    notes: [NoteSpec("2️⃣", message: Self.note("body"))]
                )
            ]
        )
    }

    @Test func nonViewTypeNotFlagged() {
        assertLint(
            OrderViewMembers.self,
            """
            struct Model {
              func save() {}
              let title: String
            }
            """
        )
    }
}
