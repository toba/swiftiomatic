@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct AssociatedValueCountTests: RuleTesting {
    private func config(warning: Int, error: Int) -> Configuration {
        let ruleName =
            ConfigurationRegistry.ruleNameCache[ObjectIdentifier(AssociatedValueCount.self)]
            ?? "associatedValueCount"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[AssociatedValueCount.self] = AssociatedValueCountConfiguration()
        c[AssociatedValueCount.self].warning = warning
        c[AssociatedValueCount.self].error = error
        return c
    }

    @Test func passesFew() {
        assertLint(
            AssociatedValueCount.self,
            """
            enum E {
                case a(Int, Int)
            }
            """,
            findings: [],
            configuration: config(warning: 5, error: 6)
        )
    }

    @Test func warnsMany() {
        assertLint(
            AssociatedValueCount.self,
            """
            enum E {
                case 1️⃣a(Int, Int, Int, Int)
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "enum case has 4 associated values; limit is 3")
            ],
            configuration: config(warning: 3, error: 6)
        )
    }
}
