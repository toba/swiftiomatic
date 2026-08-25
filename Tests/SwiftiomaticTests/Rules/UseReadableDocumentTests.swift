@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseReadableDocumentTests: RuleTesting {
  private static let fileDocument =
    "'FileDocument' is superseded on OS 27 — adopt 'ReadableDocument' and 'WritableDocument', which need a class and read and write off the main actor"
  private static let referenceDocument =
    "'ReferenceFileDocument' is superseded on OS 27 — adopt 'ReadableDocument' and 'WritableDocument', which carry '@Observable' instead of 'ObservableObject'"

  @Test func fileDocumentStructFlagged() {
    assertLint(
      UseReadableDocument.self,
      """
      struct TextDocument: 1️⃣FileDocument {
        static var readableContentTypes: [UTType] { [.plainText] }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.fileDocument)]
    )
  }

  @Test func referenceFileDocumentClassFlagged() {
    assertLint(
      UseReadableDocument.self,
      """
      final class TextDocument: 1️⃣ReferenceFileDocument {
        static var readableContentTypes: [UTType] { [.plainText] }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.referenceDocument)]
    )
  }

  @Test func extensionConformanceFlagged() {
    assertLint(
      UseReadableDocument.self,
      """
      extension TextDocument: 1️⃣FileDocument {}
      """,
      findings: [FindingSpec("1️⃣", message: Self.fileDocument)]
    )
  }

  @Test func conformanceAmongOthersFlagged() {
    assertLint(
      UseReadableDocument.self,
      """
      struct TextDocument: Sendable, 1️⃣FileDocument, Codable {
        static var readableContentTypes: [UTType] { [.plainText] }
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.fileDocument)]
    )
  }

  @Test func readableDocumentNotFlagged() {
    assertLint(
      UseReadableDocument.self,
      """
      @Observable
      final class TextDocument: ReadableDocument, WritableDocument {
        static var readableContentTypes: [UTType] { [.plainText] }
      }
      """,
      findings: []
    )
  }

  @Test func unrelatedConformanceNotFlagged() {
    assertLint(
      UseReadableDocument.self,
      """
      struct V: View {
        var body: some View { Text("") }
      }
      """,
      findings: []
    )
  }
}
