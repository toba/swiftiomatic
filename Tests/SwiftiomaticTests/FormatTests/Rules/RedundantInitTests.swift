import Testing

@testable import Swiftiomatic

@Suite struct RedundantInitTests {
  @Test func removeRedundantInit() {
    let input = """
      [1].flatMap { String.init($0) }
      """
    let output = """
      [1].flatMap { String($0) }
      """
    testFormatting(for: input, output, rule: .redundantInit)
  }

  @Test func removeRedundantInit2() {
    let input = """
      [String.self].map { Type in Type.init(foo: 1) }
      """
    let output = """
      [String.self].map { Type in Type(foo: 1) }
      """
    testFormatting(for: input, output, rule: .redundantInit)
  }

  @Test func removeRedundantInit3() {
    let input = """
      String.init(\"text\")
      """
    let output = """
      String(\"text\")
      """
    testFormatting(for: input, output, rule: .redundantInit)
  }

  @Test func dontRemoveInitInSuperCall() {
    let input = """
      class C: NSObject { override init() { super.init() } }
      """
    testFormatting(for: input, rule: .redundantInit, exclude: [.wrapFunctionBodies])
  }

  @Test func dontRemoveInitInSelfCall() {
    let input = """
      struct S { let n: Int }; extension S { init() { self.init(n: 1) } }
      """
    testFormatting(for: input, rule: .redundantInit, exclude: [.wrapFunctionBodies])
  }

  @Test func dontRemoveInitWhenPassedAsFunction() {
    let input = """
      [1].flatMap(String.init)
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func dontRemoveInitWhenUsedOnMetatype() {
    let input = """
      [String.self].map { type in type.init(1) }
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func dontRemoveInitWhenUsedOnImplicitClosureMetatype() {
    let input = """
      [String.self].map { $0.init(1) }
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func dontRemoveInitWhenUsedOnPossibleMetatype() {
    let input = """
      let something = Foo.bar.init()
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func dontRemoveInitWithExplicitSignature() {
    let input = """
      [String.self].map(Foo.init(bar:))
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func removeInitWithOpenParenOnFollowingLine() {
    let input = """
      var foo: Foo {
          Foo.init
          (
              bar: bar,
              baaz: baaz
          )
      }
      """
    let output = """
      var foo: Foo {
          Foo(
              bar: bar,
              baaz: baaz
          )
      }
      """
    testFormatting(for: input, output, rule: .redundantInit)
  }

  @Test func noRemoveInitWithOpenParenOnFollowingLineAfterComment() {
    let input = """
      var foo: Foo {
          Foo.init // foo
          (
              bar: bar,
              baaz: baaz
          )
      }
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func noRemoveInitForLowercaseType() {
    let input = """
      let foo = bar.init()
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func noRemoveInitForLocalLetType() {
    let input = """
      let Foo = Foo.self
      let foo = Foo.init()
      """
    testFormatting(for: input, rule: .redundantInit, exclude: [.propertyTypes])
  }

  @Test func noRemoveInitForLocalLetType2() {
    let input = """
      let Foo = Foo.self
      if x {
          return Foo.init(x)
      } else {
          return Foo.init(y)
      }
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func noRemoveInitInsideIfdef() {
    let input = """
      func myFunc() async throws -> String {
          #if DEBUG
          .init("foo")
          #else
          ""
          #endif
      }
      """
    testFormatting(for: input, rule: .redundantInit, exclude: [.indent])
  }

  @Test func noRemoveInitInsideIfdef2() {
    let input = """
      func myFunc() async throws(Foo) -> String {
          #if DEBUG
          .init("foo")
          #else
          ""
          #endif
      }
      """
    testFormatting(for: input, rule: .redundantInit, exclude: [.indent])
  }

  @Test func removeInitAfterCollectionLiterals() {
    let input = """
      let array = [String].init()
      let arrayElement = [String].Element.init()
      let nestedArray = [[String]].init()
      let tupleArray = [(key: String, value: Int)].init()
      let dictionary = [String: Int].init()
      """
    let output = """
      let array = [String]()
      let arrayElement = [String].Element()
      let nestedArray = [[String]]()
      let tupleArray = [(key: String, value: Int)]()
      let dictionary = [String: Int]()
      """
    testFormatting(for: input, output, rule: .redundantInit, exclude: [.propertyTypes])
  }

  @Test func preservesInitAfterTypeOfCall() {
    let input = """
      type(of: oldViewController).init()
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func preserveAsTypeInit() {
    let input = """
      let foo = (MyType.self as NSObject.Type).init()
      let bar = (MyType.self as? NSObject.Type).init()
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func dontMangleSelfInitExpressions() {
    let input = """
      // TODO: maybe we can auto-simplify in this case?
      let foo = MyType.self.init()
      let bar = (MyType.self).init()
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func removeInitAfterOptionalType() {
    let input = """
      let someOptional = String?.init("Foo")
      // (String!.init("Foo") isn't valid Swift code, so we don't test for it)
      """
    let output = """
      let someOptional = String?("Foo")
      // (String!.init("Foo") isn't valid Swift code, so we don't test for it)
      """

    testFormatting(for: input, output, rule: .redundantInit, exclude: [.propertyTypes])
  }

  @Test func preservesTryBeforeInit() {
    let input = """
      let throwing: Foo = try .init()
      let throwingOptional1: Foo = try? .init()
      let throwingOptional2: Foo = try! .init()
      """

    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func removeInitAfterGenericType() {
    let input = """
      let array = Array<String>.init()
      let dictionary = Dictionary<String, Int>.init()
      let atomicDictionary = Atomic<[String: Int]>.init()
      """
    let output = """
      let array = Array<String>()
      let dictionary = Dictionary<String, Int>()
      let atomicDictionary = Atomic<[String: Int]>()
      """

    testFormatting(for: input, output, rule: .redundantInit, exclude: [.typeSugar, .propertyTypes])
  }

  @Test func preserveNonRedundantInitInTernaryOperator() {
    let input = """
      let bar: Bar = (foo.isBar && bar.isBaaz) ? .init() : nil
      """
    testFormatting(for: input, rule: .redundantInit)
  }

  @Test func removeRedundantInitBeforeTrailingClosure() {
    let input = """
      Handler.init { print("foo") }
      """
    let output = """
      Handler { print("foo") }
      """
    testFormatting(for: input, output, rule: .redundantInit)
  }

  @Test func initOnOwnLine() {
    let input = """
      let foo = String
          .init()
      """
    let output = """
      let foo = String()
      """
    testFormatting(for: input, output, rule: .redundantInit, exclude: [.propertyTypes])
  }

  @Test func initOnOwnLine2() {
    let input = """
      let foo = String /*
           comment
          */ .init()
      """
    let output = """
      let foo = String()
      """
    testFormatting(for: input, output, rule: .redundantInit, exclude: [.propertyTypes])
  }
}
