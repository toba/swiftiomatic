@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoOnChangeDerivedStateWriteTests: RuleTesting {
  private static func message(source: String, target: String) -> String {
    "'.onChange(of: \(source))' writes '\(target)', which makes a second update. Derive '\(target)' from '\(source)' in the same mutation, or compute it where it is read"
  }

  @Test func guidanceIsConsider() {
    #expect(NoOnChangeDerivedStateWrite.guidance == .consider)
  }

  @Test func fontMenuFilterWriteFlagged() {
    assertLint(
      NoOnChangeDerivedStateWrite.self,
      """
      struct FontMenu: View {
        @State private var filter = ""
        @State private var visibleRows: [FontRow] = []
        @State private var allRows: [FontRow] = []

        var body: some View {
          TextField("Filter by name", text: $filter)
            .onChange(of: filter) {
              1️⃣visibleRows = allRows.filter { $0.name.contains(filter) }
            }
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message(source: "filter", target: "visibleRows"))]
    )
  }

  @Test func selfQualifiedAndMemberWritesFlagged() {
    assertLint(
      NoOnChangeDerivedStateWrite.self,
      """
      struct Editor: View {
        @State private var text = ""
        @State private var stats = Stats()
        var count = 0

        var body: some View {
          TextEditor(text: $text)
            .onChange(of: self.text) { old, new in
              1️⃣self.stats.words = new.split(separator: " ").count
              2️⃣count += 1
            }
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message(source: "text", target: "stats")),
        FindingSpec("2️⃣", message: Self.message(source: "text", target: "count")),
      ]
    )
  }

  @Test func actionArgumentFlagged() {
    assertLint(
      NoOnChangeDerivedStateWrite.self,
      """
      struct Counter: View {
        @State private var value = 0
        @State private var doubled = 0

        var body: some View {
          Text("x").onChange(of: value, initial: true, { 1️⃣doubled = value * 2 })
        }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message(source: "value", target: "doubled"))]
    )
  }

  @Test func writeToTheObservedStateNotFlagged() {
    assertLint(
      NoOnChangeDerivedStateWrite.self,
      """
      struct Field: View {
        @State private var text = ""

        var body: some View {
          TextField("x", text: $text).onChange(of: text) { text = String(text.prefix(10)) }
        }
      }
      """
    )
  }

  @Test func environmentValueNotFlagged() {
    assertLint(
      NoOnChangeDerivedStateWrite.self,
      """
      struct Scene: View {
        @Environment(\\.scenePhase) private var scenePhase
        @State private var lastActive = Date()

        var body: some View {
          Text("x").onChange(of: scenePhase) { lastActive = .now }
        }
      }
      """
    )
  }

  @Test func bindingTheViewDoesNotOwnNotFlagged() {
    assertLint(
      NoOnChangeDerivedStateWrite.self,
      """
      struct Picker: View {
        @Binding var selection: String
        @State private var history: [String] = []

        var body: some View {
          Text(selection).onChange(of: selection) { history = [selection] }
        }
      }
      """
    )
  }

  @Test func shadowedLocalWriteNotFlagged() {
    assertLint(
      NoOnChangeDerivedStateWrite.self,
      """
      struct Row: View {
        @State private var value = 0
        @State private var total = 0

        var body: some View {
          Text("x").onChange(of: value) {
            var total = 0
            total = value
            print(total)
          }
        }
      }
      """
    )
  }
}
