import Testing
@testable import Swiftiomatic

struct RulesRegistered: SuiteTrait, TestScoping {
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void,
    ) async throws {
        RuleRegistry.registerAllRulesOnce()
        try await function()
    }
}

extension SuiteTrait where Self == RulesRegistered {
    static var rulesRegistered: Self { .init() }
}
