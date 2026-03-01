import Testing

@testable import Swiftiomatic

@Suite struct ModifierOrderTests {
  @Test func varModifiersCorrected() {
    let input = """
      unowned private static var foo
      """
    let output = """
      private unowned static var foo
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, output, rule: .modifierOrder, options: options)
  }

  @Test func privateSetModifierNotMangled() {
    let input = """
      private(set) public weak lazy var foo
      """
    let output = """
      public private(set) lazy weak var foo
      """
    testFormatting(for: input, output, rule: .modifierOrder)
  }

  @Test func unownedUnsafeModifierNotMangled() {
    let input = """
      unowned(unsafe) lazy var foo
      """
    let output = """
      lazy unowned(unsafe) var foo
      """
    testFormatting(for: input, output, rule: .modifierOrder)
  }

  @Test func privateRequiredStaticFuncModifiers() {
    let input = """
      required static private func foo()
      """
    let output = """
      private required static func foo()
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, output, rule: .modifierOrder, options: options)
  }

  @Test func privateConvenienceInit() {
    let input = """
      convenience private init()
      """
    let output = """
      private convenience init()
      """
    testFormatting(for: input, output, rule: .modifierOrder)
  }

  @Test func spaceInModifiersLeftIntact() {
    let input = """
      weak private(set) /* read-only */
      public var
      """
    let output = """
      public private(set) /* read-only */
      weak var
      """
    testFormatting(for: input, output, rule: .modifierOrder)
  }

  @Test func spaceInModifiersLeftIntact2() {
    let input = """
      nonisolated(unsafe) public var foo: String
      """
    let output = """
      public nonisolated(unsafe) var foo: String
      """
    testFormatting(for: input, output, rule: .modifierOrder)
  }

  @Test func prefixModifier() {
    let input = """
      prefix public static func - (rhs: Foo) -> Foo
      """
    let output = """
      public static prefix func - (rhs: Foo) -> Foo
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, output, rule: .modifierOrder, options: options)
  }

  @Test func modifierOrder() {
    let input = """
      override public var foo: Int { 5 }
      """
    let output = """
      public override var foo: Int { 5 }
      """
    let options = FormatOptions(modifierOrder: ["public", "override"])
    testFormatting(
      for: input, output, rule: .modifierOrder, options: options,
      exclude: [.wrapPropertyBodies],
    )
  }

  @Test func consumingModifierOrder() {
    let input = """
      consuming public func close()
      """
    let output = """
      public consuming func close()
      """
    let options = FormatOptions(modifierOrder: ["public", "consuming"])
    testFormatting(
      for: input, output, rule: .modifierOrder, options: options,
      exclude: [.noExplicitOwnership],
    )
  }

  @Test func noConfusePostfixIdentifierWithKeyword() {
    let input = """
      var foo = .postfix
      override init() {}
      """
    testFormatting(for: input, rule: .modifierOrder)
  }

  @Test func noConfusePostfixIdentifierWithKeyword2() {
    let input = """
      var foo = postfix
      override init() {}
      """
    testFormatting(for: input, rule: .modifierOrder)
  }

  @Test func noConfuseCaseWithModifier() {
    let input = """
      public enum Foo {
          case strong
          case weak
          public init() {}
      }
      """
    testFormatting(for: input, rule: .modifierOrder)
  }

  @Test func asyncFunctionBeforeNonisolatedVar() {
    let input = """
      protocol Test: Actor {
          func test() async
          nonisolated var test2: String
      }
      """

    testFormatting(for: input, rule: .modifierOrder)
  }
}
