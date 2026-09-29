@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoDocumentControllerSubclassTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "remove the 'NSDocumentController' subclass '\(name)'. 'DocumentGroup' owns the document controller"
    }

    private static let app = """
        @main struct NotesApp: App {
          var body: some Scene {
            DocumentGroup(newDocument: NotesDocument()) { file in
              NotesView(document: file.$document)
            }
          }
        }
        """

    @Test func subclassInDocumentGroupProjectFlagged() {
        assertLint(
            NoDocumentControllerSubclass.self,
            """
            final class 1️⃣DocumentController: NSDocumentController {
              override func newDocument(_ sender: Any?) {}
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("DocumentController"))],
            otherFiles: ["/tmp/NotesApp.swift": Self.app]
        )
    }

    @Test func qualifiedSuperclassFlagged() {
        assertLint(
            NoDocumentControllerSubclass.self,
            """
            class 1️⃣Controller: AppKit.NSDocumentController {}
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("Controller"))],
            otherFiles: ["/tmp/NotesApp.swift": Self.app]
        )
    }

    @Test func documentGroupInSameFileFlagged() {
        assertLint(
            NoDocumentControllerSubclass.self,
            """
            final class 1️⃣Controller: NSDocumentController {}

            @main struct NotesApp: App {
              var body: some Scene {
                DocumentGroup(viewing: NotesDocument.self) { _ in Text("") }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("Controller"))]
        )
    }

    @Test func subclassWithoutDocumentGroupNotFlagged() {
        assertLint(
            NoDocumentControllerSubclass.self,
            """
            final class Controller: NSDocumentController {}
            """,
            findings: [],
            otherFiles: [
                "/tmp/AppDelegate.swift": """
                @main final class AppDelegate: NSObject, NSApplicationDelegate {
                  let documentGroup = "not the scene"
                }
                """
            ]
        )
    }

    @Test func otherSubclassesNotFlagged() {
        assertLint(
            NoDocumentControllerSubclass.self,
            """
            final class NotesDocument: NSDocument {}
            final class Controller: NSWindowController {}
            let controller = NSDocumentController.shared
            """,
            findings: [],
            otherFiles: ["/tmp/NotesApp.swift": Self.app]
        )
    }
}
