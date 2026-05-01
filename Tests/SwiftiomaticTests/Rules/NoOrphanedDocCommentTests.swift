@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoOrphanedDocCommentTests: RuleTesting {
    @Test func nonTriggering_attachedToProperty() {
        assertLint(
            NoOrphanedDocComment.self,
            """
            /// My great property
            var myGreatProperty: String!
            """,
            findings: []
        )
    }

    @Test func nonTriggering_fileHeader() {
        assertLint(
            NoOrphanedDocComment.self,
            """
            //////////////////////////////////////
            //
            // Copyright header.
            //
            //////////////////////////////////////
            """,
            findings: []
        )
    }

    @Test func nonTriggering_multilineDocComment() {
        assertLint(
            NoOrphanedDocComment.self,
            """
            /// Look here for more info:
            /// https://github.com.
            var myGreatProperty: String!
            """,
            findings: []
        )
    }

    @Test func triggering_singleOrphan() {
        assertLint(
            NoOrphanedDocComment.self,
            """
            1️⃣/// My great property
            // Not a doc string
            var myGreatProperty: String!
            """,
            findings: [
                FindingSpec("1️⃣", message: "doc comment is not attached to a declaration")
            ]
        )
    }

    @Test func triggering_orphanWithBlankLines() {
        assertLint(
            NoOrphanedDocComment.self,
            """
            1️⃣/// Look here for more info: https://github.com.


            // Not a doc string
            var myGreatProperty: String!
            """,
            findings: [
                FindingSpec("1️⃣", message: "doc comment is not attached to a declaration")
            ]
        )
    }

    @Test func triggering_twoOrphans() {
        assertLint(
            NoOrphanedDocComment.self,
            """
            1️⃣/// Look here for more info: https://github.com.
            // Not a doc string
            2️⃣/// My great property
            // Not a doc string
            var myGreatProperty: String!
            """,
            findings: [
                FindingSpec("1️⃣", message: "doc comment is not attached to a declaration"),
                FindingSpec("2️⃣", message: "doc comment is not attached to a declaration"),
            ]
        )
    }
}
