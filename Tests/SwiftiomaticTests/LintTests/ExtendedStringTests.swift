import Testing
@testable import Swiftiomatic

@Suite struct ExtendedStringTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    @Test func countOccurrences() {
        #expect("aabbabaaba".countOccurrences(of: "a") == 6)
        #expect("".countOccurrences(of: "a") == 0)
        #expect("\n\n".countOccurrences(of: "\n") == 2)
    }
}
