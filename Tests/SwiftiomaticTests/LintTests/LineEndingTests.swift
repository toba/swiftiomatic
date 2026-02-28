import Testing
@testable import Swiftiomatic

@Suite struct LineEndingTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    @Test func carriageReturnDoesNotCauseError() {
        #expect(
            violations(
                Example(
                    "// sm:disable:next blanket_disable_command\r\n"
                        + "// sm:disable all\r\nprint(123)\r\n",
                ),
            ).isEmpty,
        )
    }
}
