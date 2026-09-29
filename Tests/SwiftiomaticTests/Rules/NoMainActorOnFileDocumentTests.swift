@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoMainActorOnFileDocumentTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "remove '@MainActor' from '\(name)'. SwiftUI reads and writes a document off the main actor"
    }

    @Test func fileDocumentStructFlagged() {
        assertLint(
            NoMainActorOnFileDocument.self,
            """
            1️⃣@MainActor
            struct TextDocument: FileDocument {
              var text = ""
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("TextDocument"))]
        )
    }

    @Test func referenceFileDocumentClassFlagged() {
        assertLint(
            NoMainActorOnFileDocument.self,
            """
            1️⃣@MainActor final class Canvas: ObservableObject, ReferenceFileDocument {
              var shapes: [Shape] = []
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("Canvas"))]
        )
    }

    @Test func qualifiedConformanceFlagged() {
        assertLint(
            NoMainActorOnFileDocument.self,
            """
            1️⃣@MainActor struct Notes: SwiftUI.FileDocument {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("Notes"))]
        )
    }

    @Test func conformanceInSameFileExtensionFlagged() {
        assertLint(
            NoMainActorOnFileDocument.self,
            """
            1️⃣@MainActor struct Notes {
              var text = ""
            }

            extension Notes: FileDocument {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("Notes"))]
        )
    }

    @Test func mainActorExtensionAddingConformanceFlagged() {
        assertLint(
            NoMainActorOnFileDocument.self,
            """
            struct Notes {}

            1️⃣@MainActor extension Notes: FileDocument {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("Notes"))]
        )
    }

    @Test func documentWithoutMainActorNotFlagged() {
        assertLint(
            NoMainActorOnFileDocument.self,
            """
            struct TextDocument: FileDocument {
              var text = ""
            }
            """,
            findings: []
        )
    }

    @Test func mainActorOnOtherTypesNotFlagged() {
        assertLint(
            NoMainActorOnFileDocument.self,
            """
            @MainActor struct Editor: View {
              var body: some View { Text("") }
            }

            @MainActor final class FileDocumentStore: FileDocumentLoader {}
            """,
            findings: []
        )
    }

    @Test func mainActorOnMemberNotFlagged() {
        assertLint(
            NoMainActorOnFileDocument.self,
            """
            struct TextDocument: FileDocument {
              @MainActor func refreshPreview() {}
            }
            """,
            findings: []
        )
    }
}
