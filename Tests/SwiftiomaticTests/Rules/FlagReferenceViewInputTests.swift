@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagReferenceViewInputTests: RuleTesting {
  private static func message(_ name: String, _ type: String) -> String {
    "'\(name)' stores the '@Observable' class '\(type)' as an input. SwiftUI compares the reference, not the values the view reads. Pass the values the view reads, or read the model from the environment"
  }

  @Test func guidanceIsConsider() {
    #expect(FlagReferenceViewInput.guidance == .consider)
  }

  /// The Thesis `PDFNavigator` shape: the class is declared in another file.
  @Test func otherFileObservableClassInputFlagged() {
    assertLint(
      FlagReferenceViewInput.self,
      """
      struct PDFPane: View {
        1️⃣let navigator: PDFNavigator

        var body: some View { Text("\\(navigator.page)") }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("navigator", "PDFNavigator"))],
      otherFiles: [
        "/tmp/PDFNavigator.swift": """
        @Observable final class PDFNavigator {
          var page = 0
        }
        """
      ]
    )
  }

  @Test func observableClassInputFlagged() {
    assertLint(
      FlagReferenceViewInput.self,
      """
      @Observable final class Library {
        var books: [Book] = []
      }

      struct Shelf: View {
        1️⃣let library: Library
        2️⃣var fallback: Library?

        var body: some View { Text("\\(library.books.count)") }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: Self.message("library", "Library")),
        FindingSpec("2️⃣", message: Self.message("fallback", "Library")),
      ]
    )
  }

  @Test func bindableInputFlagged() {
    assertLint(
      FlagReferenceViewInput.self,
      """
      @Observable class Settings { var name = "" }

      struct Form: View {
        1️⃣@Bindable var settings: Settings

        var body: some View { TextField("Name", text: $settings.name) }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("settings", "Settings"))]
    )
  }

  @Test func ownedStateAndEnvironmentNotFlagged() {
    assertLint(
      FlagReferenceViewInput.self,
      """
      @Observable final class Library { var books: [Book] = [] }

      struct Root: View {
        @State private var library = Library()
        @State private var other: Library = .init()
        @Environment(Library.self) private var shared

        var body: some View { Text("x") }
      }
      """
    )
  }

  @Test func plainClassAndOtherFileTypesNotFlagged() {
    assertLint(
      FlagReferenceViewInput.self,
      """
      final class Cache { var items: [Int] = [] }

      struct Row: View {
        let cache: Cache
        let store: Store

        var body: some View { Text("x") }
      }
      """
    )
  }

  @Test func genericParameterNotFlagged() {
    assertLint(
      FlagReferenceViewInput.self,
      """
      @Observable final class Value { var x = 0 }

      private struct OptionSetRow<Value: OptionSet>: View {
        var value: Value

        var body: some View { Text("x") }
      }
      """
    )
  }
}
