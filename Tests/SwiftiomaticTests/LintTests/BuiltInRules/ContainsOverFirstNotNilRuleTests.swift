import Testing
@testable import Swiftiomatic

@Suite struct ContainsOverFirstNotNilRuleTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    @Test func firstReason() {
        let example = Example("↓myList.first { $0 % 2 == 0 } != nil")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer `contains` over `first(where:) != nil`")
    }

    @Test func firstIndexReason() {
        let example = Example("↓myList.firstIndex { $0 % 2 == 0 } != nil")
        let violations = violations(example)

        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Prefer `contains` over `firstIndex(where:) != nil`")
    }

    // MARK: - Private

    private func violations(_ example: Example, config: Any? = nil) -> [StyleViolation] {
        guard let config = makeConfig(config, ContainsOverFirstNotNilRule.identifier) else {
            return []
        }

        return violations(example, config: config)
    }
}
