@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct NoLocalDocCommentsTests: RuleTesting {
    @Test func nonTriggering_regularCommentInBody() {
        assertLint(
            NoLocalDocComments.self,
            """
            func foo() {
                // Local scope documentation should use normal comments.
                print("foo")
            }
            """,
            findings: []
        )
    }

    @Test func nonTriggering_docCommentOnProperty() {
        assertLint(
            NoLocalDocComments.self,
            """
            /// My great property
            var myGreatProperty: String!
            """,
            findings: []
        )
    }

    @Test func nonTriggering_nestedFunctionDocComment() {
        assertLint(
            NoLocalDocComments.self,
            """
            func outer() {
                /// Documentation for the nested function.
                func inner() {}
                inner()
            }
            """,
            findings: []
        )
    }

    @Test func triggering_docCommentInFunctionBody() {
        assertLint(
            NoLocalDocComments.self,
            """
            func foo() {
                1️⃣/// Docstring inside a function declaration
                print("foo")
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message:
                        "use a regular comment (//) inside a function body, not a doc comment (///)"
                )
            ]
        )
    }

    @Test func triggering_docCommentInInitBody() {
        assertLint(
            NoLocalDocComments.self,
            """
            struct S {
                init() {
                    1️⃣/// Bad doc comment
                    let x = 1
                    _ = x
                }
            }
            """,
            findings: [
                FindingSpec(
                    "1️⃣",
                    message:
                        "use a regular comment (//) inside a function body, not a doc comment (///)"
                )
            ]
        )
    }
}
