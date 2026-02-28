import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct RuleFilterTests {
    @Test func rulesFilterExcludesEnabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ],
        )
        let enabledRules: [any Rule] = [
            RuleMock1(),
            CorrectableRuleMock(),
        ]
        let rulesFilter = RuleFilter(
            allRules: allRules,
            enabledRules: enabledRules,
        )

        let filteredRules = rulesFilter.rules(excluding: [.enabled])

        #expect(Set(filteredRules.list.keys) == Set([RuleMock2.identifier]))
    }

    @Test func rulesFilterExcludesDisabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ],
        )
        let enabledRules: [any Rule] = [
            RuleMock1(),
            CorrectableRuleMock(),
        ]
        let rulesFilter = RuleFilter(
            allRules: allRules,
            enabledRules: enabledRules,
        )

        let filteredRules = rulesFilter.rules(excluding: [.disabled])

        #expect(
            Set(filteredRules.list.keys) == Set([
                RuleMock1.identifier,
                CorrectableRuleMock.identifier,
            ]),
        )
    }

    @Test func rulesFilterExcludesUncorrectableRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ],
        )
        let enabledRules: [any Rule] = [
            RuleMock1(),
            CorrectableRuleMock(),
        ]
        let rulesFilter = RuleFilter(
            allRules: allRules,
            enabledRules: enabledRules,
        )

        let filteredRules = rulesFilter.rules(excluding: [.uncorrectable])

        #expect(Set(filteredRules.list.keys) == Set([CorrectableRuleMock.identifier]))
    }

    @Test func rulesFilterExcludesUncorrectableDisabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ],
        )
        let enabledRules: [any Rule] = [
            RuleMock1(),
            CorrectableRuleMock(),
        ]
        let rulesFilter = RuleFilter(
            allRules: allRules,
            enabledRules: enabledRules,
        )

        let filteredRules = rulesFilter.rules(excluding: [.disabled, .uncorrectable])

        #expect(Set(filteredRules.list.keys) == Set([CorrectableRuleMock.identifier]))
    }

    @Test func rulesFilterExcludesUncorrectableEnabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ],
        )
        let enabledRules: [any Rule] = [
            RuleMock1(),
        ]
        let rulesFilter = RuleFilter(
            allRules: allRules,
            enabledRules: enabledRules,
        )

        let filteredRules = rulesFilter.rules(excluding: [.enabled, .uncorrectable])

        #expect(Set(filteredRules.list.keys) == Set([CorrectableRuleMock.identifier]))
    }
}

// MARK: - Mocks

private struct RuleMock1: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }

    static let description = RuleDescription(
        identifier: "RuleMock1", name: "",
        description: "", kind: .style,
    )

    init() { /* conformance for test */ }
    init(configuration _: Any) { self.init() }

    func validate(file _: SwiftSource) -> [RuleViolation] {
        []
    }
}

private struct RuleMock2: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }

    static let description = RuleDescription(
        identifier: "RuleMock2", name: "",
        description: "", kind: .style,
    )

    init() { /* conformance for test */ }
    init(configuration _: Any) { self.init() }

    func validate(file _: SwiftSource) -> [RuleViolation] {
        []
    }
}

private struct CorrectableRuleMock: CorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }

    static let description = RuleDescription(
        identifier: "CorrectableRuleMock", name: "",
        description: "", kind: .style,
    )

    init() { /* conformance for test */ }
    init(configuration _: Any) { self.init() }

    func validate(file _: SwiftSource) -> [RuleViolation] {
        []
    }

    func correct(file _: SwiftSource) -> Int {
        0
    }
}
