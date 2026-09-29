import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct NoPrintChangesInBodyTests: RuleTesting {
    private static func message(_ name: String) -> String {
        "remove 'Self.\(name)()' from shipping code, or wrap it in '#if DEBUG'"
    }

    @Test func letDiscardInBody() {
        assertFormatting(
            NoPrintChangesInBody.self,
            input: """
                struct V: View {
                  var body: some View {
                    1️⃣let _ = Self._printChanges()
                    Text("x")
                  }
                }
                """,
            expected: """
                struct V: View {
                  var body: some View {
                    Text("x")
                  }
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message("_printChanges"))]
        )
    }

    @Test func bareCallInMiddle() {
        assertFormatting(
            NoPrintChangesInBody.self,
            input: """
                func f() {
                  a()
                  1️⃣Self._logChanges()
                  b()
                }
                """,
            expected: """
                func f() {
                  a()
                  b()
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message("_logChanges"))]
        )
    }

    @Test func discardAssignment() {
        assertFormatting(
            NoPrintChangesInBody.self,
            input: """
                func f() {
                  a()
                  1️⃣_ = Self._printChanges()
                }
                """,
            expected: """
                func f() {
                  a()
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message("_printChanges"))]
        )
    }

    @Test func firstStatementFollowedByBlankLine() {
        assertFormatting(
            NoPrintChangesInBody.self,
            input: """
                var body: some View {
                  1️⃣let _ = Self._printChanges()

                  Text("x")
                }
                """,
            expected: """
                var body: some View {
                  Text("x")
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message("_printChanges"))]
        )
    }

    @Test func insideIfDebugKept() {
        assertFormatting(
            NoPrintChangesInBody.self,
            input: """
                var body: some View {
                  #if DEBUG
                  let _ = Self._printChanges()
                  #endif
                  Text("x")
                }
                """,
            expected: """
                var body: some View {
                  #if DEBUG
                  let _ = Self._printChanges()
                  #endif
                  Text("x")
                }
                """,
            findings: []
        )
    }

    @Test func insideNonDebugIfConfigFlagged() {
        assertFormatting(
            NoPrintChangesInBody.self,
            input: """
                var body: some View {
                  #if os(iOS)
                  1️⃣let _ = Self._printChanges()
                  #endif
                  Text("x")
                }
                """,
            expected: """
                var body: some View {
                  #if os(iOS)
                  #endif
                  Text("x")
                }
                """,
            findings: [FindingSpec("1️⃣", message: Self.message("_printChanges"))]
        )
    }

    @Test func nearMissesIgnored() {
        assertFormatting(
            NoPrintChangesInBody.self,
            input: """
                func f() {
                  let x = Self._printChanges()
                  Other._printChanges()
                  Self.printChanges()
                  Self._printChanges(1)
                }
                """,
            expected: """
                func f() {
                  let x = Self._printChanges()
                  Other._printChanges()
                  Self.printChanges()
                  Self._printChanges(1)
                }
                """,
            findings: []
        )
    }
}
