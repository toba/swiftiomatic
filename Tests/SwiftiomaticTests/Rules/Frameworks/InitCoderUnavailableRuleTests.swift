import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct InitCoderUnavailableRuleTests {
  @Test func lintExamples() async {
    await verifyLint(
      TestExamples(from: InitCoderUnavailableRule.self),
      config: makeConfig(nil, InitCoderUnavailableRule.identifier)!,
      skipCommentTests: true,
      skipStringTests: true,
    )
  }

  @Test func fatalErrorBodyTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class Foo: UIView {
          required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """
      ),
      rule: InitCoderUnavailableRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func emptyBodyTriggersViolation() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class Foo: UIView {
          required init?(coder: NSCoder) {
          }
        }
        """
      ),
      rule: InitCoderUnavailableRule.identifier,
    )
    #expect(violations.count == 1)
  }

  @Test func alreadyMarkedUnavailableDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class Foo: UIView {
          @available(*, unavailable)
          required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """
      ),
      rule: InitCoderUnavailableRule.identifier,
    )
    #expect(violations.isEmpty)
  }

  @Test func realImplementationDoesNotTrigger() async throws {
    let violations = try await ruleViolations(
      Example(
        """
        class Foo: UIView {
          required init?(coder: NSCoder) {
            super.init(coder: coder)
          }
        }
        """
      ),
      rule: InitCoderUnavailableRule.identifier,
    )
    #expect(violations.isEmpty)
  }
}
