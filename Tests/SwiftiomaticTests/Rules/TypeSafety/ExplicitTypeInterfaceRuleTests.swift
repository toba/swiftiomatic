import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct ExplicitTypeInterfaceRuleTests {
  // MARK: - Non-triggering (default config)

  @Test func allowsAnnotatedInstanceVar() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        var myVar: Int? = 0
      }
      """)
  }

  @Test func allowsAnnotatedInstanceLet() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let myVar: Int? = 0, s: String = ""
      }
      """)
  }

  @Test func allowsAnnotatedStaticVar() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        static var myVar: Int? = 0
      }
      """)
  }

  @Test func allowsAnnotatedClassVar() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        class var myVar: Int? = 0
      }
      """)
  }

  @Test func allowsPatternBindingInIfCase() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      func f() {
          if case .failure(let error) = errorCompletion {}
      }
      """)
  }

  // MARK: - Triggering (default config)

  @Test func detectsUnannotatedInstanceVar() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        var 1️⃣myVar = 0
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsUnannotatedInstanceLet() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let 1️⃣mylet = 0
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsUnannotatedStaticVar() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        static var 1️⃣myStaticVar = 0
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsUnannotatedClassVar() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        class var 1️⃣myClassVar = 0
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsMultipleBindingsInOneLet() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let 1️⃣myVar = Int(0), 2️⃣s = ""
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }

  @Test func detectsUnannotatedSetInit() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let 1️⃣myVar = Set<Int>(0)
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Local vars

  @Test func detectsUnannotatedLocalVar() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      "func foo() {\nlet 1️⃣intVal = 1\n}",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsUnannotatedLocalVarInClosure() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      func foo() {
          bar {
              let 1️⃣x = 1
          }
      }
      """,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func allowsAnnotatedLocalVar() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      "func foo() {\nlet intVal: Int = 1\n}")
  }

  // MARK: - Excluded: local

  @Test func excludeLocalVars() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      "func foo() {\nlet intVal = 1\n}",
      configuration: ["excluded": ["local"]])
  }

  @Test func excludeLocalStillDetectsInstance() async {
    await assertViolates(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        var myVar = 0
      }
      """,
      configuration: ["excluded": ["local"]])
  }

  // MARK: - Excluded: static

  @Test func excludeStaticVars() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        static var myStaticVar = 0
      }
      """,
      configuration: ["excluded": ["static"]])
  }

  @Test func excludeStaticLets() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        static let myStaticLet = 0
      }
      """,
      configuration: ["excluded": ["static"]])
  }

  @Test func excludeStaticStillDetectsInstanceVar() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        var 1️⃣myVar = 0

      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["excluded": ["static"]])
  }

  @Test func excludeStaticStillDetectsClassVar() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        class var 1️⃣myClassVar = 0
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["excluded": ["static"]])
  }

  // MARK: - Allow redundancy

  @Test func allowRedundancyForSharedSingleton() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        static let shared = Foo()
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyForTypeConstructor() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let myVar = Int(0)
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyForGenericTypeConstructor() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let myVar = Set<Int>(0)
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyForTryBangConstructor() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let regex = try! NSRegularExpression(pattern: ".*")
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyForTryOptionalConstructor() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let regex = try? NSRegularExpression(pattern: ".*")
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyForArrayConstructor() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let array = [String]()
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyForDictConstructor() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let dict = [String: String]()
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyForNestedDictConstructor() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let dict = [String: [String: Array<String>]]()
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyForSelfReference() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let l10n = L10n.Communication.self
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyStillDetectsAnnotated() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        var myVar: Int? = 0
      }
      """,
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyStillDetectsLiteralVar() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        var 1️⃣myVar = 0

      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyStillDetectsArrayLiteral() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let 1️⃣array = ["foo", "bar"]
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["allow_redundancy": true])
  }

  @Test func allowRedundancyStillDetectsDictLiteral() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
        let 1️⃣dict = ["foo": "bar"]
      }
      """,
      findings: [FindingSpec("1️⃣")],
      configuration: ["allow_redundancy": true])
  }

  // MARK: - Embedded in statements

  @Test func allowsGuardLetBinding() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      func foo() {
          var bar: String?
          guard let strongBar = bar else {
              return
          }
      }
      """)
  }

  @Test func allowsSwitchCaseLetBinding() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      struct SomeError: Error {}
      var error: Error?
      switch error {
      case let error as SomeError: break
      default: break
      }
      """)
  }

  // MARK: - Capture groups

  @Test func allowsWeakCaptureGroup() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      var k: Int = 0
      _ = { [weak k] in
          print(k)
      }
      """)
  }

  @Test func allowsUnownedCaptureGroup() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      var k: Int = 0
      _ = { [unowned k] in
          print(k)
      }
      """)
  }

  @Test func allowsMultipleCaptureGroups() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      class Foo {
          func bar() {
              var k: Int = 0
              _ = { [weak self, weak k] in
                  guard let strongSelf = self else { return }
              }
          }
      }
      """)
  }

  // MARK: - For-in declarations

  @Test func allowsForInLoop() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      func foo() {
          let elements: [Int] = [1, 2]
          for element in elements {}
      }
      """)
  }

  @Test func allowsForInWithTupleDestructuring() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      func foo() {
          let elements: [Int] = [1, 2]
          for (index, element) in elements.enumerated() {}
      }
      """)
  }

  // MARK: - Switch case declarations

  @Test func allowsSwitchCasePatternBinding() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      enum Foo {
          case failure(Any)
          case success(Any)
      }
      func bar() {
          let foo: Foo = .success(1)
          switch foo {
          case .failure(let error):
              let bar: Int = 1
          case .success(let result):
              let bar: Int = 2
          }
      }
      """)
  }

  @Test func allowsSwitchCaseTupleBinding() async {
    await assertNoViolation(
      ExplicitTypeInterfaceRule.self,
      """
      enum Foo {
          case failure(Any, Any)
      }
      func foo() {
          switch foo {
          case var (x, y): break
          }
      }
      """)
  }

  @Test func detectsUnannotatedLetInSwitchCaseBody() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      enum Foo {
          case failure(Any)
          case success(Any)
      }
      func bar() {
          let foo: Foo = .success(1)
          switch foo {
          case .failure(let error): let 1️⃣fooBar = 1
          case .success(let result): let 2️⃣fooBar = 1
          }
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }

  @Test func detectsUnannotatedLetInSwitchDefault() async {
    await assertLint(
      ExplicitTypeInterfaceRule.self,
      """
      enum Foo {
          case failure(Any, Any)
      }
      func foo() {
          let foo: Foo = .failure(1, 1)
          switch foo {
          case var .failure(x, y): let 1️⃣fooBar = 1
          default: let 2️⃣fooBar = 1
          }
      }
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")])
  }
}
