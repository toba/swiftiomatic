@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct LineLengthLimitTests: RuleTesting {
    private func config(warning: Int, error: Int, ignoresURLs: Bool = true) -> Configuration {
        let ruleName =
            ConfigurationRegistry.ruleNameCache[ObjectIdentifier(LineLengthLimit.self)]
            ?? "lineLengthLimit"
        var c = Configuration.forTesting(enabledRule: ruleName)
        c[LineLengthLimit.self] = LineLengthLimitConfiguration()
        c[LineLengthLimit.self].warning = warning
        c[LineLengthLimit.self].error = error
        c[LineLengthLimit.self].ignoresURLs = ignoresURLs
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

    @Test func ignoresBareURL() {
        assertLint(
            LineLengthLimit.self,
            """
            let url = "https://example.com/a/very/long/path/that/keeps/going"
            """,
            findings: [],
            configuration: config(warning: 40, error: 200)
        )
    }

    @Test func ignoresMarkdownLinkURL() {
        assertLint(
            LineLengthLimit.self,
            """
            /// See [the guide](https://example.com/a/very/long/path/that/keeps/going).
            let a = 1
            """,
            findings: [],
            configuration: config(warning: 40, error: 200)
        )
    }

    @Test func ignoresAutolinkURL() {
        assertLint(
            LineLengthLimit.self,
            """
            /// See <https://example.com/a/very/long/path/that/keeps/going>
            let a = 1
            """,
            findings: [],
            configuration: config(warning: 40, error: 200)
        )
    }

    /// A property access is not a URL. Upstream SwiftLint fixed the same false negative in
    /// commit `e3f29820`, where a link detector read `post.id` as a host name.
    @Test func warnsOnPropertyAccess() {
        assertLint(
            LineLengthLimit.self,
            """
            1️⃣let value = firstLongIdentifierName + secondLongIdentifierName + post.id
            """,
            findings: [
                FindingSpec("1️⃣", message: "line is 72 characters; limit is 40")
            ],
            configuration: config(warning: 40, error: 200)
        )
    }

    @Test func warnsWhenLineIsLongWithoutItsURL() {
        assertLint(
            LineLengthLimit.self,
            """
            1️⃣let url = "https://example.com/x" + firstLongIdentifierName + secondName
            """,
            findings: [
                FindingSpec("1️⃣", message: "line is 50 characters; limit is 40")
            ],
            configuration: config(warning: 40, error: 200)
        )
    }

    @Test func countsURLWhenIgnoresURLsIsOff() {
        assertLint(
            LineLengthLimit.self,
            """
            1️⃣let url = "https://example.com/a/very/long/path/that/keeps/going"
            """,
            findings: [
                FindingSpec("1️⃣", message: "line is 65 characters; limit is 40")
            ],
            configuration: config(warning: 40, error: 200, ignoresURLs: false)
        )
    }
}
