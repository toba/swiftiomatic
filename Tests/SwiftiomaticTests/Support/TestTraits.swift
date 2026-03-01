import Testing

@testable import Swiftiomatic

/// Ensures rules are registered and SourceKit is disabled before test execution.
/// SourceKit is disabled to prevent SIGSEGV during process exit (apple/swift#55112).
private let _testSetup: Void = {
  RuleRegistry.registerAllRulesOnce()
  disableSourceKitForTesting()
}()

struct RulesRegistered: SuiteTrait, TestScoping {
  func provideScope(
    for test: Test,
    testCase: Test.Case?,
    performing function: @Sendable () async throws -> Void,
  ) async throws {
    _ = _testSetup
    try await function()
  }
}

extension SuiteTrait where Self == RulesRegistered {
  static var rulesRegistered: Self { .init() }
}
