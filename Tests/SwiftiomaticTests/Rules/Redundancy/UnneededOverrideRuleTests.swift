import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct UnneededOverrideRuleTests {
  @Test func includeAffectInits() async {
    let nonTriggeringExamples =
      [
        Example(
          """
          override init() {
              super.init(frame: .zero)
          }
          """,
        ),
        Example(
          """
          override init?() {
              super.init()
          }
          """,
        ),
        Example(
          """
          override init!() {
              super.init()
          }
          """,
        ),
        Example(
          """
          private override init() {
              super.init()
          }
          """,
        ),
      ] + UnneededOverrideRule.nonTriggeringExamples

    let triggeringExamples = [
      Example(
        """
        class Foo {
            ↓override init() {
                super.init()
            }
        }
        """,
      ),
      Example(
        """
        class Foo {
            ↓public override init(frame: CGRect) {
                super.init(frame: frame)
            }
        }
        """,
      ),
    ]

    let corrections = [
      Example(
        """
        class Foo {
            ↓override init(frame: CGRect) {
                super.init(frame: frame)
            }
        }
        """,
      ): Example(
        """
        class Foo {
        }
        """,
      )
    ]

    let description = TestExamples(from: UnneededOverrideRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
      corrections: corrections,
    )

    await verifyRule(description, ruleConfiguration: ["affect_initializers": true])
  }
}
