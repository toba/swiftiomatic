@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ClosureBodyLengthTests: RuleTesting {
    private func config(warning: Int, error: Int) -> Configuration {
        let ruleName =
            ConfigurationRegistry.ruleNameCache[ObjectIdentifier(ClosureBodyLength.self)]
            ?? "closureBodyLength"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[ClosureBodyLength.self] = ClosureBodyLengthConfiguration()
        c[ClosureBodyLength.self].warning = warning
        c[ClosureBodyLength.self].error = error
        return c
    }

    @Test func passesShortClosure() {
        assertLint(
            ClosureBodyLength.self,
            """
            let f = { (x: Int) in
                print(x)
            }
            """,
            findings: [],
            configuration: config(warning: 3, error: 5)
        )
    }

    @Test func warnsLongClosure() {
        assertLint(
            ClosureBodyLength.self,
            """
            let f = 1️⃣{ (x: Int) in
                print(1)
                print(2)
                print(3)
                print(4)
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "closure body has 4 lines; limit is 2")
            ],
            configuration: config(warning: 2, error: 5)
        )
    }
}
