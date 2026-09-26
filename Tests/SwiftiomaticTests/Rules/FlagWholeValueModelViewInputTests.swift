@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagWholeValueModelViewInputTests: RuleTesting {
  private static func message(_ name: String, _ type: String, _ count: Int) -> String {
    "'\(name)' stores the whole value model '\(type)' (\(count) stored properties) as an input. A change to any property updates this view. Pass only the properties the view reads"
  }

  private static func partialMessage(_ name: String, _ type: String, _ read: String) -> String {
    "'\(name)' stores the whole value '\(type)' as an input but reads only \(read). A change to any other property still updates this view. Pass only the properties the view reads"
  }

  @Test func guidanceIsConsider() {
    #expect(FlagWholeValueModelViewInput.guidance == .consider)
  }

  @Test func largeStructInputFlagged() {
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      struct Book {
        var title: String
        var author: String
        var pages: Int
        var rating: Double
        var notes: String
        static let empty = Book(title: "", author: "", pages: 0, rating: 0, notes: "")
        var summary: String { title + author }
      }

      struct BookRow: View {
        1️⃣let book: Book
        2️⃣@Binding var draft: Book

        var body: some View { Text(book.title) }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("book", "Book", 5)),
        FindingSpec("2️⃣", message: Self.message("draft", "Book", 5)),
      ]
    )
  }

  @Test func storedPropertiesInExtensionsCount() {
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      struct Profile {
        var name: String
        var email: String
        var avatar: URL
      }

      extension Profile {
        struct Nested {}
      }

      struct Profile2 {
        let a, b, c, d, e: Int
      }

      struct Card: View {
        let profile: Profile
        1️⃣let other: Profile2?

        var body: some View { Text(profile.name) }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("other", "Profile2", 5))]
    )
  }

  @Test func smallStructNotFlagged() {
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      private struct FontRow: Equatable, Identifiable {
        let name: String
        let fit: RowFit
        var id: String { name }
      }

      private struct FontPreview: View {
        let row: FontRow
        var body: some View { Text(row.name) }
      }
      """
    )
  }

  @Test func stateAndGenericParameterNotFlagged() {
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      struct Value {
        var a = 0, b = 0, c = 0, d = 0, e = 0
      }

      struct Editor: View {
        @State private var draft = Value()
        var body: some View { Text("x") }
      }

      private struct OptionSetRow<Value: OptionSet>: View {
        var value: Value
        var body: some View { Text("x") }
      }
      """
    )
  }

  @Test func viewTypeInputNotFlagged() {
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      struct Header: View {
        var a = 0, b = 0, c = 0, d = 0, e = 0
        var body: some View { Text("x") }
      }

      struct Page: View {
        let header: Header
        var body: some View { header }
      }
      """
    )
  }

  @Test func outOfFileModelReadByPropertiesFlagged() {
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      private struct TagSummary: View {
        1️⃣let tag: TagJSON

        var body: some View {
          VStack {
            Text(tag.name)
            if !tag.detail.isEmpty { Text(tag.detail) }
            Text("\\(tag.issueCount) issues")
          }
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣", message: Self.partialMessage("tag", "TagJSON", "'detail', 'issueCount', 'name'"))
      ]
    )
  }

  @Test func outOfFileInputUsedWholeNotFlagged() {
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      struct Row: View {
        let tag: TagJSON
        let other: TagJSON
        let date: Date
        let symbol: StatusSymbol

        var body: some View {
          VStack {
            Text(tag.name); Text(tag.detail); Text(tag.owner)
            TagEditor(tag: tag)
            Text(other.name); Text(other.detail)
            Text(date.year); Text(date.month); Text(date.day)
            Text(symbol.a); symbol.b.c; symbol.d(); Text(symbol.e)
          }
        }
      }
      """
    )
  }

  @Test func deferredUseAndSameFileViewForwardDoNotCountAsWholeUse() {
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      private struct LintAlertRow: View {
        1️⃣let alert: LintAlert

        var body: some View {
          HStack(spacing: 8) {
            Button { Dispatcher.emit(RevealLintAlert(alert)) } label: {
              Label {
                Text(alert.message)
              } icon: {
                Image(systemName: alert.level.symbolName).foregroundStyle(alert.level.tint)
              }
            }
            if !alert.suggestions.isEmpty { QuickFixControl(alert: alert) }
          }
        }
      }

      private struct QuickFixControl: View {
        let alert: LintAlert

        var body: some View {
          if alert.suggestions.count == 1, let replacement = alert.suggestions.first {
            Button {
              Dispatcher.emit(ApplyLintFix(alert: alert, replacement: replacement))
            } label: { Image(systemName: "wand.and.sparkles") }
          }
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: Self.partialMessage("alert", "LintAlert", "'level', 'message', 'suggestions'"))
      ]
    )
  }

  @Test func wholeUseInLabelClosureStillCounts() {
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      struct Row: View {
        let tag: TagJSON

        var body: some View {
          Button { open() } label: {
            Text(tag.name); Text(tag.detail); Text(tag.owner)
            TagBadge(tag: tag)
          }
        }
      }
      """
    )
  }
  @Test func observableClassInputNotFlagged() {
    // From Thesis `AskInspector.swift`. `AskState` is an `@Observable` class in another file. The
    // `@Bindable` and `@Environment(AskState.self)` uses show that it is an observable reference.
    assertLint(
      FlagWholeValueModelViewInput.self,
      """
      struct QuestionField: View {
        @Bindable var ask: AskState
        var body: some View { TextField("", text: $ask.question) }
      }

      private struct StreamedAnswer: View {
        let ask: AskState
        var body: some View {
          Text(ask.answer)
          Text(ask.phase.title)
          ForEach(ask.sources) { Text($0.title) }
        }
      }

      private struct Sources: View {
        @Environment(SourceStore.self) private var environmentStore
        let store: SourceStore
        var body: some View {
          Text(store.first)
          Text(store.second)
          Text(store.third)
        }
      }
      """
    )
  }
}
