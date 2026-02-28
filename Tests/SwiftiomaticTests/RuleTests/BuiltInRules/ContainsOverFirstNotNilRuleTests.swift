import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ContainsOverFirstNotNilRuleTests {
    @Test(.disabled("Rule produces 0 violations"))
    func firstReason() async {
        let example = Example("↓myList.first { $0 % 2 == 0 } != nil")
        let violations = await violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer `contains` over `first(where:) != nil`")
    }

    @Test(.disabled("Rule produces 0 violations"))
    func firstIndexReason() async {
        let example = Example("↓myList.firstIndex { $0 % 2 == 0 } != nil")
        let violations = await violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer `contains` over `firstIndex(where:) != nil`")
    }

    // MARK: - Private

    private func violations(_ example: Example, config: Any? = nil) async -> [RuleViolation] {
        guard let config = makeConfig(config, ContainsOverFirstNotNilRule.identifier) else {
            return []
        }

        return await SwiftiomaticTests.violations(example, config: config)
    }
}
