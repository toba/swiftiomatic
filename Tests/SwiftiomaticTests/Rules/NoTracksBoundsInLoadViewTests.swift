@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoTracksBoundsInLoadViewTests: RuleTesting {
    private static let message =
        "set 'tracksTextAttachmentViewBounds' in the initializer. TextKit reads it before 'loadView()' runs"

    @Test func bareAssignmentFlagged() {
        assertLint(
            NoTracksBoundsInLoadView.self,
            """
            final class ChipProvider: NSTextAttachmentViewProvider {
              override func loadView() {
                1️⃣tracksTextAttachmentViewBounds = true
                view = ChipView()
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func selfAssignmentFlagged() {
        assertLint(
            NoTracksBoundsInLoadView.self,
            """
            final class ChipProvider: NSTextAttachmentViewProvider {
              override func loadView() {
                super.loadView()
                1️⃣self.tracksTextAttachmentViewBounds = true
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func assignmentInClosureInsideLoadViewFlagged() {
        assertLint(
            NoTracksBoundsInLoadView.self,
            """
            final class ChipProvider: NSTextAttachmentViewProvider {
              override func loadView() {
                DispatchQueue.main.async {
                  1️⃣self.tracksTextAttachmentViewBounds = false
                }
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message)]
        )
    }

    @Test func assignmentInInitializerNotFlagged() {
        assertLint(
            NoTracksBoundsInLoadView.self,
            """
            final class ChipProvider: NSTextAttachmentViewProvider {
              override init(
                textAttachment: NSTextAttachment,
                parentView: UIView?,
                textLayoutManager: NSTextLayoutManager?,
                location: NSTextLocation
              ) {
                super.init(
                  textAttachment: textAttachment,
                  parentView: parentView,
                  textLayoutManager: textLayoutManager,
                  location: location)
                tracksTextAttachmentViewBounds = true
              }

              override func loadView() {
                view = ChipView()
              }
            }
            """,
            findings: []
        )
    }

    @Test func readAndOtherMethodsNotFlagged() {
        assertLint(
            NoTracksBoundsInLoadView.self,
            """
            final class ChipProvider: NSTextAttachmentViewProvider {
              override func loadView() {
                let tracks = tracksTextAttachmentViewBounds
                view = ChipView(tracks: tracks)
                func configure() { tracksTextAttachmentViewBounds = true }
              }

              func loadView(animated: Bool) {
                tracksTextAttachmentViewBounds = animated
              }

              func reset() {
                tracksTextAttachmentViewBounds = false
              }
            }
            """,
            findings: []
        )
    }
}
