import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct DropRedundantOverrideTests: RuleTesting {
    private static func message(_ name: String) -> String {
        """
        override of '\(name)' only forwards to super with identical arguments. \
        Remove it when nothing depends on the declaration
        """
    }

    @Test func plainForward() {
        assertLint(
            DropRedundantOverride.self,
            """
            class Foo: Bar {
              1️⃣override func update() {
                super.update()
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("update"))]
        )
    }

    @Test func forwardWithLabeledArgs() {
        assertLint(
            DropRedundantOverride.self,
            """
            class Foo: Bar {
              1️⃣override func setEditing(_ editing: Bool, animated: Bool) {
                super.setEditing(editing, animated: animated)
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("setEditing"))]
        )
    }

    @Test func extraStatementNotFlagged() {
        assertLint(
            DropRedundantOverride.self,
            """
            class Foo: Bar {
              override func update() {
                super.update()
                log("did update")
              }
            }
            """,
            findings: []
        )
    }

    @Test func differentArgumentsNotFlagged() {
        assertLint(
            DropRedundantOverride.self,
            """
            class Foo: Bar {
              override func setEditing(_ editing: Bool, animated: Bool) {
                super.setEditing(editing, animated: false)
              }
            }
            """,
            findings: []
        )
    }

    @Test func excludedTestLifecycleNotFlagged() {
        assertLint(
            DropRedundantOverride.self,
            """
            class FooTests: XCTestCase {
              override func setUp() {
                super.setUp()
              }
            }
            """,
            findings: []
        )
    }

    @Test func attributedOverrideNotFlagged() {
        assertLint(
            DropRedundantOverride.self,
            """
            class Foo: Bar {
              @available(*, deprecated)
              override func update() {
                super.update()
              }
            }
            """,
            findings: []
        )
    }

    @Test func tryAwaitForward() {
        assertLint(
            DropRedundantOverride.self,
            """
            class Foo: Bar {
              1️⃣override func load() async throws {
                try await super.load()
              }
            }
            """,
            findings: [FindingSpec("1️⃣", message: Self.message("load"))]
        )
    }

    @Test func tryBangNotFlagged() {
        assertLint(
            DropRedundantOverride.self,
            """
            class Foo: Bar {
              override func load() {
                try! super.load()
              }
            }
            """,
            findings: []
        )
    }

    @Test func staticOverrideNotFlagged() {
        assertLint(
            DropRedundantOverride.self,
            """
            class Foo: Bar {
              override static func register() {
                super.register()
              }
            }
            """,
            findings: []
        )
    }

    /// The rule reports and never deletes. A forwarding override can exist to prove the signature
    /// still matches the superclass, which is the whole point of a compilation-only test file.
    @Test func formatLeavesForwardingOverridesInPlace() {
        let source = """
            class Player: Record {
              override func willInsert(_ db: Database) throws {
                try super.willInsert(db)
              }

              override func aroundInsert(_ db: Database, insert: () throws -> InsertionSuccess) throws {
                try super.aroundInsert(db, insert: insert)
              }

              override func didInsert(_ inserted: InsertionSuccess) {
                super.didInsert(inserted)
              }
            }
            """
        assertFormatting(DropRedundantOverride.self, input: source, expected: source, findings: [])
    }
}
