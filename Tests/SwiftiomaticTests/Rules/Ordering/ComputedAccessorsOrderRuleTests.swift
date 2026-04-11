import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ComputedAccessorsOrderRuleTests {
  // MARK: - Default (get-set) order — no violations

  @Test func getSetPropertyNoViolation() async {
    await assertNoViolation(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          var foo: Int {
              get { return 3 }
              set { _abc = newValue }
          }
      }
      """)
  }

  @Test func getterOnlyPropertyNoViolation() async {
    await assertNoViolation(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          var foo: Int {
              return 20
          }
      }
      """)
  }

  @Test func protocolPropertyNoViolation() async {
    await assertNoViolation(
      ComputedAccessorsOrderRule.self,
      """
      protocol Foo {
          var foo: Int { get set }
      }
      """)
  }

  @Test func getSetSubscriptNoViolation() async {
    await assertNoViolation(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          subscript(i: Int) -> Int {
              get { return 3 }
              set { _abc = newValue }
          }
      }
      """)
  }

  @Test func nestedPropertyNoViolation() async {
    await assertNoViolation(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          var foo: Int {
              struct Bar {
                  var bar: Int {
                      get { return 1 }
                      set { _ = newValue }
                  }
              }
              return Bar().bar
          }
      }
      """)
  }

  @Test func inlineGetWithAttributeNoViolation() async {
    await assertNoViolation(
      ComputedAccessorsOrderRule.self,
      """
      var _objCTaggedPointerBits: UInt {
          @inline(__always) get { return 0 }
          set { print(newValue) }
      }
      """)
  }

  @Test func mutatingGetNoViolation() async {
    await assertNoViolation(
      ComputedAccessorsOrderRule.self,
      """
      var next: Int? {
          mutating get {
              defer { self.count += 1 }
              return self.count
          }
          set {
              self.count = newValue
          }
      }
      """)
  }

  @Test func nonmutatingSetNoViolation() async {
    await assertNoViolation(
      ComputedAccessorsOrderRule.self,
      """
      extension Reactive where Base: UITapGestureRecognizer {
          var tapped: CocoaAction<Base>? {
              get {
                  return associatedAction.withValue { $0.flatMap { $0.action } }
              }
              nonmutating set {
                  setAction(newValue)
              }
          }
      }
      """)
  }

  // MARK: - Default (get-set) order — violations

  @Test func setBeforeGetPropertyViolation() async {
    await assertLint(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          var foo: Int {
              1️⃣set {
                  print(newValue)
              }
              get {
                  return 20
              }
          }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Computed properties should first declare the getter and then the setter")
      ])
  }

  @Test func setBeforeGetStaticPropertyViolation() async {
    await assertLint(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          static var foo: Int {
              1️⃣set {
                  print(newValue)
              }
              get {
                  return 20
              }
          }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Computed properties should first declare the getter and then the setter")
      ])
  }

  @Test func setBeforeGetInlineViolation() async {
    await assertLint(
      ComputedAccessorsOrderRule.self,
      """
      var foo: Int {
          1️⃣set { print(newValue) }
          get { return 20 }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Computed properties should first declare the getter and then the setter")
      ])
  }

  @Test func setBeforeGetExtensionViolation() async {
    await assertLint(
      ComputedAccessorsOrderRule.self,
      """
      extension Foo {
          var bar: Bool {
              1️⃣set { print(bar) }
              get { _bar }
          }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Computed properties should first declare the getter and then the setter")
      ])
  }

  @Test func setBeforeMutatingGetViolation() async {
    await assertLint(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          var foo: Int {
              1️⃣set {
                  print(newValue)
              }
              mutating get {
                  return 20
              }
          }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Computed properties should first declare the getter and then the setter")
      ])
  }

  @Test func setBeforeGetSubscriptViolation() async {
    await assertLint(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          subscript(i: Int) -> Int {
              1️⃣set {
                  print(i)
              }
              get {
                  return 20
              }
          }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Computed subscripts should first declare the getter and then the setter")
      ])
  }

  // MARK: - set_get configuration — no violations

  @Test func setGetConfigNoViolation() async {
    await assertNoViolation(
      ComputedAccessorsOrderRule.self,
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
      configuration: ["order": "set_get"])
  }

  // MARK: - set_get configuration — violations

  @Test func getBeforeSetPropertyWithSetGetConfig() async {
    await assertLint(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          var foo: Int {
              1️⃣get {
                  print(newValue)
              }
              set {
                  return 20
              }
          }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Computed properties should first declare the setter and then the getter")
      ],
      configuration: ["order": "set_get"])
  }

  @Test func getBeforeSetSubscriptWithSetGetConfig() async {
    await assertLint(
      ComputedAccessorsOrderRule.self,
      """
      class Foo {
          subscript(i: Int) -> Int {
              1️⃣get {
                  return 20
              }
              set {
                  print(i)
              }
          }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Computed subscripts should first declare the setter and then the getter")
      ],
      configuration: ["order": "set_get"])
  }
}
