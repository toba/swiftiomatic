import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct RedundantOverrideRuleTests {
  // MARK: - Non-triggering (default: affect_initializers = false)

  @Test func overrideWithExtraWorkDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override func bar() {
              super.bar()
              print("hi")
          }
      }
      """
    )
  }

  @Test func overrideWithUnavailableAttributeDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          @available(*, unavailable)
          override func bar() {
              super.bar()
          }
      }
      """
    )
  }

  @Test func overrideWithObjcDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          @objc override func bar() {
              super.bar()
          }
      }
      """
    )
  }

  @Test func overrideCallingTwiceDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override func bar() {
              super.bar()
              super.bar()
          }
      }
      """
    )
  }

  @Test func overrideWithTryBangDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override func bar() throws {
              try! super.bar()
          }
      }
      """
    )
  }

  @Test func overrideWithTryQuestionDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override func bar() throws {
              try? super.bar()
          }
      }
      """
    )
  }

  @Test func overrideFlippingArgDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override func bar(arg: Bool) {
              super.bar(arg: !arg)
          }
      }
      """
    )
  }

  @Test func overrideChangingArgDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override func bar(_ arg: Int) {
              super.bar(arg + 1)
          }
      }
      """
    )
  }

  @Test func overrideOmittingArgsDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override func bar(_ arg: Int) {
              super.bar()
          }
      }
      """
    )
  }

  @Test func overrideChangingLabelsDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override func bar(arg: Int, _ arg3: Bool) {
              super.bar(arg2: arg, arg3: arg3)
          }
      }
      """
    )
  }

  @Test func overrideWithTrailingClosureDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override func bar(animated: Bool, completion: () -> Void) {
              super.bar(animated: animated) {
              }
          }
      }
      """
    )
  }

  @Test func overrideWithDefaultArgDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Baz: Foo {
          override func bar(value: String = "Hello") {
              super.bar(value: value)
          }
      }
      """
    )
  }

  @Test func excludedMethodDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class FooTestCase: XCTestCase {
          override func setUp() {
              super.setUp()
          }
      }
      """,
      configuration: ["excluded_methods": ["setUp"]]
    )
  }

  @Test func initOverrideDoesNotTriggerByDefault() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      class Foo {
          override init(i: Int) {
              super.init(i: i)
          }
      }
      """
    )
  }

  // MARK: - Triggering (default: affect_initializers = false)

  @Test func simpleOverrideTriggers() async {
    await assertLint(
      RedundantOverrideRule.self,
      """
      class Foo {
          1️⃣override func bar() {
              super.bar()
          }
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func overrideWithReturnTriggers() async {
    await assertLint(
      RedundantOverrideRule.self,
      """
      class Foo {
          1️⃣override func bar() {
              return super.bar()
          }
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func overrideWithCommentTriggers() async {
    await assertLint(
      RedundantOverrideRule.self,
      """
      class Foo {
          1️⃣override func bar() {
              super.bar()
              // comments don't affect this
          }
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func asyncOverrideTriggers() async {
    await assertLint(
      RedundantOverrideRule.self,
      """
      class Foo {
          1️⃣override func bar() async {
              await super.bar()
          }
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func throwingOverrideTriggers() async {
    await assertLint(
      RedundantOverrideRule.self,
      """
      class Foo {
          1️⃣override func bar() throws {
              try super.bar()
          }
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func overrideWithArgsTriggers() async {
    await assertLint(
      RedundantOverrideRule.self,
      """
      class Foo {
          1️⃣override func bar(arg: Bool) throws {
              try super.bar(arg: arg)
          }
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func overridePassingCompletionTriggers() async {
    await assertLint(
      RedundantOverrideRule.self,
      """
      class Foo {
          1️⃣override func bar(animated: Bool, completion: () -> Void) {
              super.bar(animated: animated, completion: completion)
          }
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  // MARK: - Corrections (default: affect_initializers = false)

  @Test func correctsSimpleOverride() async {
    await assertFormatting(
      RedundantOverrideRule.self,
      input: """
        class Foo {
            1️⃣override func bar() {
                super.bar()
            }
        }
        """,
      expected: """
        class Foo {
        }
        """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsOverridePreservesOtherMembers() async {
    await assertFormatting(
      RedundantOverrideRule.self,
      input: """
        class Foo {
            1️⃣override func bar() {
                super.bar()
            }

            // This is another function
            func baz() {}
        }
        """,
      expected: """
        class Foo {

            // This is another function
            func baz() {}
        }
        """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsOverrideButNotInitByDefault() async {
    await assertFormatting(
      RedundantOverrideRule.self,
      input: """
        class Foo {
            1️⃣override func foo() { super.foo() }
            override init(i: Int) {
                super.init(i: i)
            }
        }
        """,
      expected: """
        class Foo {
            override init(i: Int) {
                super.init(i: i)
            }
        }
        """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  // MARK: - affect_initializers = true

  @Test func initWithDifferentSuperArgsDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      override init() {
          super.init(frame: .zero)
      }
      """,
      configuration: ["affect_initializers": true]
    )
  }

  @Test func failableInitDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      override init?() {
          super.init()
      }
      """,
      configuration: ["affect_initializers": true]
    )
  }

  @Test func implicitlyUnwrappedInitDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      override init!() {
          super.init()
      }
      """,
      configuration: ["affect_initializers": true]
    )
  }

  @Test func privateOverrideInitDoesNotTrigger() async {
    await assertNoViolation(
      RedundantOverrideRule.self,
      """
      private override init() {
          super.init()
      }
      """,
      configuration: ["affect_initializers": true]
    )
  }

  @Test func simpleInitOverrideTriggers() async {
    await assertLint(
      RedundantOverrideRule.self,
      """
      class Foo {
          1️⃣override init() {
              super.init()
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["affect_initializers": true]
    )
  }

  @Test func publicInitOverrideTriggers() async {
    await assertLint(
      RedundantOverrideRule.self,
      """
      class Foo {
          1️⃣public override init(frame: CGRect) {
              super.init(frame: frame)
          }
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["affect_initializers": true]
    )
  }

  @Test func correctsInitOverride() async {
    await assertFormatting(
      RedundantOverrideRule.self,
      input: """
        class Foo {
            1️⃣override init(frame: CGRect) {
                super.init(frame: frame)
            }
        }
        """,
      expected: """
        class Foo {
        }
        """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["affect_initializers": true]
    )
  }
}
