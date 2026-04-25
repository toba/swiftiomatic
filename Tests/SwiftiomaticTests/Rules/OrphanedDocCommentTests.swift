@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct OrphanedDocCommentTests: RuleTesting {
    @Test func nonTriggering_attachedToProperty() {
        assertLint(
            OrphanedDocComment.self,
            """
            /// My great property
            var myGreatProperty: String!
            """,
            findings: []
        )
    }

    @Test func nonTriggering_fileHeader() {
        assertLint(
            OrphanedDocComment.self,
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
            OrphanedDocComment.self,
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
            OrphanedDocComment.self,
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
            OrphanedDocComment.self,
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
            OrphanedDocComment.self,
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
