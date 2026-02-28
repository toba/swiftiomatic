import Testing
@testable import Swiftiomatic

@Suite struct DisableAllTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    /// Example violations. Could be replaced with other single violations.
    private let violatingPhrases = [
        Example("let r = 0"), // Violates identifier_name
        Example(#"let myString:String = """#), // Violates colon_whitespace
        Example("// TODO: Some todo"), // Violates todo
    ]

    // MARK: Violating Phrase

    /// Tests whether example violating phrases trigger when not applying disable rule
    @Test func violatingPhrase() {
        for violatingPhrase in violatingPhrases {
            #expect(
                violations(violatingPhrase.with(code: violatingPhrase.code + "\n")).count == 1,
            )
        }
    }

    // MARK: Enable / Disable Base

    /// Tests whether swiftlint:disable all protects properly
    @Test func disableAll() {
        for violatingPhrase in violatingPhrases {
            let code = "// swiftlint:disable all\n" + violatingPhrase.code + "\n// swiftlint:enable all\n"
            let protectedPhrase = violatingPhrase.with(code: code)
            #expect(
                violations(protectedPhrase).isEmpty,
            )
        }
    }

    /// Tests whether swiftlint:enable all unprotects properly
    @Test func enableAll() {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase = violatingPhrase.with(
                code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                // swiftlint:enable all
                \(violatingPhrase.code)\n
                """,
            )
            #expect(
                violations(unprotectedPhrase).count == 1,
            )
        }
    }

    // MARK: Enable / Disable Previous

    /// Tests whether swiftlint:disable:previous all protects properly
    @Test func disableAllPrevious() {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase =
                violatingPhrase
                    .with(
                        code: """
                        \(violatingPhrase.code)
                        // swiftlint:disable:previous all\n
                        """,
                    )
            #expect(
                violations(protectedPhrase).isEmpty,
            )
        }
    }

    /// Tests whether swiftlint:enable:previous all unprotects properly
    @Test func enableAllPrevious() {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase = violatingPhrase.with(
                code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                \(violatingPhrase.code)
                // swiftlint:enable:previous all
                // swiftlint:enable all
                """,
            )
            #expect(
                violations(unprotectedPhrase).count == 1,
            )
        }
    }

    // MARK: Enable / Disable Next

    /// Tests whether swiftlint:disable:next all protects properly
    @Test func disableAllNext() {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = violatingPhrase.with(
                code: "// swiftlint:disable:next all\n" + violatingPhrase.code,
            )
            #expect(
                violations(protectedPhrase).isEmpty,
            )
        }
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    @Test func enableAllNext() {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase = violatingPhrase.with(
                code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                // swiftlint:enable:next all
                \(violatingPhrase.code)
                // swiftlint:enable all
                """,
            )
            #expect(
                violations(unprotectedPhrase).count == 1,
            )
        }
    }

    // MARK: Enable / Disable This

    /// Tests whether swiftlint:disable:this all protects properly
    @Test func disableAllThis() {
        for violatingPhrase in violatingPhrases {
            let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
            let protectedPhrase = violatingPhrase.with(
                code: rawViolatingPhrase + "// swiftlint:disable:this all\n",
            )
            #expect(
                violations(protectedPhrase).isEmpty,
            )
        }
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    @Test func enableAllThis() {
        for violatingPhrase in violatingPhrases {
            let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
            let unprotectedPhrase = violatingPhrase.with(
                code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                \(rawViolatingPhrase)// swiftlint:enable:this all
                // swiftlint:enable all
                """,
            )
            #expect(
                violations(unprotectedPhrase).count == 1,
            )
        }
    }
}
