import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoRootBranchSwapInBodyTests: RuleTesting {
    private static func message(_ names: [String]) -> String {
        let list = names.map { "'\($0)'" }.joined(separator: ", ")
        return "'body' swaps its root view between \(list). Keep one stable root view and put the condition inside it"
    }

    private static func note(_ name: String) -> String { "this branch builds '\(name)'" }

    @Test func ifElseWithDifferentRootsFlagged() {
        assertLint(
            NoRootBranchSwapInBody.self,
            """
            struct EditorView: View {
              let isLoading: Bool
              var body: some View {
                1️⃣if isLoading {
                  2️⃣ProgressView()
                } else {
                  3️⃣List { Text("a") }
                    .padding()
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message(["ProgressView", "List"]),
                    notes: [
                        NoteSpec("2️⃣", message: Self.note("ProgressView")),
                        NoteSpec("3️⃣", message: Self.note("List")),
                    ]
                )
            ]
        )
    }

    @Test func switchWithDifferentRootsFlagged() {
        assertLint(
            NoRootBranchSwapInBody.self,
            """
            struct EditorView: View {
              let mode: Mode
              var body: some View {
                1️⃣switch mode {
                case .a: 2️⃣Text("a")
                case .b: 3️⃣Image(systemName: "b")
                default: 4️⃣Text("c")
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message(["Text", "Image"]),
                    notes: [
                        NoteSpec("2️⃣", message: Self.note("Text")),
                        NoteSpec("3️⃣", message: Self.note("Image")),
                        NoteSpec("4️⃣", message: Self.note("Text")),
                    ]
                )
            ]
        )
    }

    @Test func viewModifierBodyFlagged() {
        assertLint(
            NoRootBranchSwapInBody.self,
            """
            struct Highlight: ViewModifier {
              let isOn: Bool
              func body(content: Content) -> some View {
                1️⃣if isOn {
                  2️⃣content.background(.yellow)
                } else {
                  3️⃣EmptyView()
                }
              }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message: Self.message(["content", "EmptyView"]),
                    notes: [
                        NoteSpec("2️⃣", message: Self.note("content")),
                        NoteSpec("3️⃣", message: Self.note("EmptyView")),
                    ]
                )
            ]
        )
    }

    @Test func ifWithoutElseNotFlagged() {
        assertLint(
            NoRootBranchSwapInBody.self,
            """
            struct EditorView: View {
              let isLoading: Bool
              var body: some View {
                if isLoading {
                  ProgressView()
                }
              }
            }
            """
        )
    }

    @Test func sameRootTypeNotFlagged() {
        assertLint(
            NoRootBranchSwapInBody.self,
            """
            struct EditorView: View {
              let isLoading: Bool
              var body: some View {
                if isLoading {
                  Text("Loading").foregroundStyle(.secondary)
                } else {
                  Text("Done")
                }
              }
            }
            """
        )
    }

    @Test func stableRootNotFlagged() {
        assertLint(
            NoRootBranchSwapInBody.self,
            """
            struct EditorView: View {
              let isLoading: Bool
              var body: some View {
                VStack {
                  if isLoading { ProgressView() } else { List { Text("a") } }
                }
              }
            }
            """
        )
    }

    @Test func availabilityCheckNotFlagged() {
        assertLint(
            NoRootBranchSwapInBody.self,
            """
            struct EditorView: View {
              var body: some View {
                if #available(macOS 27, *) {
                  GlassPanel()
                } else {
                  Panel()
                }
              }
            }
            """
        )
    }

    @Test func severalStatementsNotFlagged() {
        assertLint(
            NoRootBranchSwapInBody.self,
            """
            struct EditorView: View {
              let isLoading: Bool
              var body: some View {
                let title = "a"
                if isLoading { ProgressView() } else { Text(title) }
              }
            }
            """
        )
    }

    @Test func nonViewTypeNotFlagged() {
        assertLint(
            NoRootBranchSwapInBody.self,
            """
            struct Builder {
              let isLoading: Bool
              var body: some View {
                if isLoading { ProgressView() } else { Text("a") }
              }
            }
            """
        )
    }
}
