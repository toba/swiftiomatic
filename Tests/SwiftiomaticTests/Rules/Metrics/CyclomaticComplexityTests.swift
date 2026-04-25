@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct CyclomaticComplexityTests: RuleTesting {
    private func config(warning: Int = 10, error: Int = 20) -> Configuration {
        let ruleName =
            ConfigurationRegistry.ruleNameCache[ObjectIdentifier(CyclomaticComplexity.self)]
            ?? "cyclomaticComplexity"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[CyclomaticComplexity.self] = CyclomaticComplexityConfiguration()
        c[CyclomaticComplexity.self].warning = warning
        c[CyclomaticComplexity.self].error = error
        return c
    }

    @Test func passesUnderThreshold() {
        assertLint(
            CyclomaticComplexity.self,
            """
            func ok() {
                if a {}
                if b {}
            }
            """,
            findings: [],
            configuration: config(warning: 3, error: 5)
        )
    }

    @Test func warnsAboveWarningThreshold() {
        assertLint(
            CyclomaticComplexity.self,
            """
            1️⃣func tooComplex() {
                if a {}
                if b {}
                if c {}
                if d {}
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "function has cyclomatic complexity 4; limit is 3")
            ],
            configuration: config(warning: 3, error: 6)
        )
    }

    @Test func errorsAboveErrorThreshold() {
        assertLint(
            CyclomaticComplexity.self,
            """
            1️⃣func tooComplex() {
                if a {}
                if b {}
                if c {}
                if d {}
                if e {}
                if f {}
            }
            """,
            findings: [
                FindingSpec("1️⃣", message: "function has cyclomatic complexity 6; limit is 5")
            ],
            configuration: config(warning: 3, error: 5)
        )
    }

    @Test func nestedFunctionsCountedSeparately() {
        assertLint(
            CyclomaticComplexity.self,
            """
            func outer() {
                if a {}
                func inner() {
                    if x {}
                    if y {}
                    if z {}
                }
            }
            """,
            findings: [],
            configuration: config(warning: 3, error: 5)
        )
    }
}
