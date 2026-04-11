import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct RedundantRawValuesRuleTests {
  @Test func lintExamples() async {
    await verifyLint(
      TestExamples(from: RedundantRawValuesRule.self),
      config: makeConfig(nil, RedundantRawValuesRule.identifier)!,
      skipCommentTests: true,
      skipStringTests: true,
    )
  }

  @Test func correctionExamples() async {
    await verifyCorrections(
      TestExamples(from: RedundantRawValuesRule.self),
      config: makeConfig(nil, RedundantRawValuesRule.identifier)!,
      disableCommands: [],
      shouldTestMultiByteOffsets: false,
    )
  }

  @Test func individualRedundantValueTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        enum Foo: String {
          case bar = "bar"
          case baz = "quux"
        }
        """
      ),
      rule: RedundantRawValuesRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func nonRedundantValueDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        enum Foo: String {
          case bar = "BAR"
        }
        """
      ),
      rule: RedundantRawValuesRule.identifier,
    )
    #expect(violations.isEmpty)
  }

  @Test func intEnumDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        enum Foo: Int {
          case bar = 1
        }
        """
      ),
      rule: RedundantRawValuesRule.identifier,
    )
    #expect(violations.isEmpty)
  }
}
