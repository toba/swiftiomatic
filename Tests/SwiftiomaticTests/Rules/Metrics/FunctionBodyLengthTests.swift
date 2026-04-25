@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FunctionBodyLengthTests: RuleTesting {
    private func config(warning: Int, error: Int) -> Configuration {
        let ruleName =
            ConfigurationRegistry.ruleNameCache[ObjectIdentifier(FunctionBodyLength.self)]
            ?? "functionBodyLength"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[FunctionBodyLength.self] = FunctionBodyLengthConfiguration()
        c[FunctionBodyLength.self].warning = warning
        c[FunctionBodyLength.self].error = error
        return c
    }

    @Test func passesShortFunction() {
        assertLint(
            FunctionBodyLength.self,
            """
            func short() {
                let a = 1
                let b = 2
            }
            """,
            findings: [],
            configuration: config(warning: 5, error: 10)
        )
    }

    @Test func warnsLongFunction() {
        assertLint(
            FunctionBodyLength.self,
            """
            1️⃣func long() {
                let a = 1
                let b = 2
                let c = 3
                let d = 4
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "function body has 4 lines; limit is 3")
            ],
            configuration: config(warning: 3, error: 6)
        )
    }
}
