@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ExpiringTodoTests: RuleTesting {
    @Test func nonTriggering_plainTodos() {
        assertLint(
            ExpiringTodo.self,
            """
            // notaTODO:
            // notaFIXME:
            // TODO(note)
            // FIXME(note)
            /* FIXME: */
            /* TODO: */
            """,
            findings: []
        )
    }

    @Test func nonTriggering_farFutureDate() {
        assertLint(
            ExpiringTodo.self,
            """
            // TODO: [12/31/9999]
            """,
            findings: []
        )
    }

    @Test func triggering_expiredTodoLineComment() {
        assertLint(
            ExpiringTodo.self,
            """
            // TODO: [1️⃣01/01/2020]
            let x = 1
            """,
            findings: [
                FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")
            ]
        )
    }

    @Test func triggering_expiredFixmeLineComment() {
        assertLint(
            ExpiringTodo.self,
            """
            // FIXME: [1️⃣10/14/2019]
            let x = 1
            """,
            findings: [
                FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")
            ]
        )
    }

    @Test func triggering_badFormatting() {
        assertLint(
            ExpiringTodo.self,
            """
            // TODO: [1️⃣9999/14/10]
            let x = 1
            """,
            findings: [
                FindingSpec("1️⃣", message: "expiring TODO/FIXME is incorrectly formatted")
            ]
        )
    }

    @Test func customDateFormat() {
        var configuration = Configuration.forTesting(enabledRule: "ExpiringTodo")
        var ruleConfig = ExpiringTodoConfiguration()
        ruleConfig.dateFormat = "yyyy-MM-dd"
        ruleConfig.dateSeparator = "-"
        configuration[ExpiringTodo.self] = ruleConfig

        assertLint(
            ExpiringTodo.self,
            """
            // TODO: [1️⃣2020-01-01]
            let x = 1
            """,
            findings: [
                FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")
            ],
            configuration: configuration
        )
    }
}
