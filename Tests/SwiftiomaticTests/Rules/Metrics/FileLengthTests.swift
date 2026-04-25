@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct FileLengthTests: RuleTesting {
    private func config(warning: Int, error: Int) -> Configuration {
        let ruleName =
            ConfigurationRegistry.ruleNameCache[ObjectIdentifier(FileLength.self)]
            ?? "fileLength"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[FileLength.self] = FileLengthConfiguration()
        c[FileLength.self].warning = warning
        c[FileLength.self].error = error
        return c
    }

    @Test func passesShortFile() {
        assertLint(
            FileLength.self,
            """
            let a = 1
            let b = 2
            """,
            findings: [],
            configuration: config(warning: 5, error: 10)
        )
    }

    @Test func warnsLongFile() {
        assertLint(
            FileLength.self,
            """
            1️⃣let a = 1
            let b = 2
            let c = 3
            let d = 4
            let e = 5
            """,
            findings: [
                FindingSpec("1️⃣", message: "file has 5 lines; limit is 3")
            ],
            configuration: config(warning: 3, error: 10)
        )
    }
}
