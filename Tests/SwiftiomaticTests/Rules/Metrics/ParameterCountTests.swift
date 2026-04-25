@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ParameterCountTests: RuleTesting {
    private func config(warning: Int, error: Int, ignoresDefaults: Bool = true) -> Configuration {
        let ruleName =
            ConfigurationRegistry.ruleNameCache[ObjectIdentifier(ParameterCount.self)]
            ?? "parameterCount"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[ParameterCount.self] = ParameterCountConfiguration()
        c[ParameterCount.self].warning = warning
        c[ParameterCount.self].error = error
        c[ParameterCount.self].ignoresDefaultParameters = ignoresDefaults
        return c
    }

    @Test func passesFew() {
        assertLint(
            ParameterCount.self,
            "func ok(a: Int, b: Int) {}",
            findings: [],
            configuration: config(warning: 3, error: 5)
        )
    }

    @Test func warnsManyParameters() {
        assertLint(
            ParameterCount.self,
            "1️⃣func tooMany(a: Int, b: Int, c: Int, d: Int) {}",
            findings: [
                FindingSpec("1️⃣", message: "function has 4 parameters; limit is 3")
            ],
            configuration: config(warning: 3, error: 6)
        )
    }

    @Test func defaultParamsIgnored() {
        assertLint(
            ParameterCount.self,
            "func ok(a: Int, b: Int = 1, c: Int = 2, d: Int = 3) {}",
            findings: [],
            configuration: config(warning: 2, error: 5, ignoresDefaults: true)
        )
    }
}
