@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct LineLengthLimitTests: RuleTesting {
    private func config(warning: Int, error: Int) -> Configuration {
        let ruleName =
            ConfigurationRegistry.ruleNameCache[ObjectIdentifier(LineLengthLimit.self)]
            ?? "lineLengthLimit"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[LineLengthLimit.self] = LineLengthLimitConfiguration()
        c[LineLengthLimit.self].warning = warning
        c[LineLengthLimit.self].error = error
        return c
    }

    @Test func passesShortLines() {
        assertLint(
            LineLengthLimit.self,
            """
            let a = 1
            let b = 2
            """,
            findings: [],
            configuration: config(warning: 20, error: 30)
        )
    }

    @Test func warnsLongLine() {
        assertLint(
            LineLengthLimit.self,
            """
            let short = 1
            1️⃣let longerLine = "this is a relatively long line"
            """,
            findings: [
                FindingSpec("1️⃣", message: "line is 49 characters; limit is 20")
            ],
            configuration: config(warning: 20, error: 80)
        )
    }
}
