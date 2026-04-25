@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct TypeBodyLengthTests: RuleTesting {
    private func config(warning: Int, error: Int) -> Configuration {
        let ruleName =
            ConfigurationRegistry.ruleNameCache[ObjectIdentifier(TypeBodyLength.self)]
            ?? "typeBodyLength"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[TypeBodyLength.self] = TypeBodyLengthConfiguration()
        c[TypeBodyLength.self].warning = warning
        c[TypeBodyLength.self].error = error
        return c
    }

    @Test func passesShortType() {
        assertLint(
            TypeBodyLength.self,
            """
            struct S {
                let a = 1
                let b = 2
            }
            """,
            findings: [],
            configuration: config(warning: 5, error: 10)
        )
    }

    @Test func warnsLongClass() {
        assertLint(
            TypeBodyLength.self,
            """
            1️⃣class C {
                let a = 1
                let b = 2
                let c = 3
                let d = 4
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "type body has 4 lines; limit is 3")
            ],
            configuration: config(warning: 3, error: 6)
        )
    }
}
