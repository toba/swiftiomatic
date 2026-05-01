@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FlagExpiringTodoTests: RuleTesting {
    @Test func nonTriggering_plainTodos() {
        assertLint(
            FlagExpiringTodo.self,
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
            FlagExpiringTodo.self,
            """
            // TODO: [12/31/9999]
            """,
            findings: []
        )
    }

    @Test func triggering_expiredTodoLineComment() {
        assertLint(
            FlagExpiringTodo.self,
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
            FlagExpiringTodo.self,
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
            FlagExpiringTodo.self,
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
        var configuration = Configuration.forTesting(enabledRule: "FlagExpiringTodo")
        var ruleConfig = ExpiringTodoConfiguration()
        ruleConfig.dateFormat = "yyyy-MM-dd"
        ruleConfig.dateSeparator = "-"
        configuration[FlagExpiringTodo.self] = ruleConfig

        assertLint(
            FlagExpiringTodo.self,
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
