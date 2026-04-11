import Testing

@testable import Swiftiomatic

@Suite struct RuleRegistryTests {
  @Test func ruleCountMatchesAfterRegistration() {
    RuleRegistry.registerAllRulesOnce()
    #expect(RuleRegistry.shared.ruleCount > 300, "Should have 300+ rules registered")
  }

  @Test func listNotEmptyWhenAccessedViaShared() {
    // This is the critical test — shared.list must never return empty
    // even if accessed before explicit registerAllRulesOnce()
    let rules = RuleRegistry.shared.list.rules
    #expect(!rules.isEmpty, "Registry.shared.list should never be empty")
  }
}
