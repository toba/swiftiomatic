import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ComputedAccessorsOrderRuleTests {
  @Test func setGetConfiguration() async {
    let nonTriggeringExamples = [
      Example(
        """
        class Foo {
            var foo: Int {
                set {
                    print(newValue)
                }
                get {
                    return 20
                }
            }
        }
        """,
      )
    ]
    let triggeringExamples = [
      Example(
        """
        class Foo {
            var foo: Int {
                ↓get {
                    print(newValue)
                }
                set {
                    return 20
                }
            }
        }
        """,
      )
    ]

    let description = TestExamples(from: ComputedAccessorsOrderRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["order": "set_get"])
  }

  @Test func getSetPropertyReason() async {
    let example = Example(
      """
      class Foo {
          var foo: Int {
              set {
                  return 20
              }
              get {
                  print(newValue)
              }
          }
      }
      """,
    )

    #expect(
      await ruleViolations(example).first?.reason
        == "Computed properties should first declare the getter and then the setter",
    )
  }

  @Test func getSetSubscriptReason() async {
    let example = Example(
      """
      class Foo {
          subscript(i: Int) -> Int {
              set {
                  print(i)
              }
              get {
                  return 20
              }
          }
      }
      """,
    )

    #expect(
      await ruleViolations(example).first?.reason
        == "Computed subscripts should first declare the getter and then the setter",
    )
  }

  @Test func setGetPropertyReason() async {
    let example = Example(
      """
      class Foo {
          var foo: Int {
              get {
                  print(newValue)
              }
              set {
                  return 20
              }
          }
      }
      """,
    )

    #expect(
      await ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason
        == "Computed properties should first declare the setter and then the getter",
    )
  }

  @Test func setGetSubscriptReason() async {
    let example = Example(
      """
      class Foo {
          subscript(i: Int) -> Int {
              get {
                  return 20
              }
              set {
                  print(i)
              }
          }
      }
      """,
    )

    #expect(
      await ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason
        == "Computed subscripts should first declare the setter and then the getter",
    )
  }

  private func ruleViolations(
    _ example: Example,
    ruleConfiguration: Any? = nil
  ) async -> [RuleViolation] {
    guard let config = makeConfig(ruleConfiguration, ComputedAccessorsOrderRule.identifier)
    else {
      return []
    }

    return await violations(example, config: config)
  }
}
