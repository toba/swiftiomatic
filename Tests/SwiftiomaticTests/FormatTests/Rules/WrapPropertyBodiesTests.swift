import Testing

@testable import Swiftiomatic

@Suite struct WrapPropertyBodiesTests {
  // MARK: - Computed Properties

  @Test func wrapSingleLineComputedProperty() {
    let input = """
      var bar: String { "bar" }
      """
    let output = """
      var bar: String {
          "bar"
      }
      """
    testFormatting(for: input, output, rule: .wrapPropertyBodies)
  }

  @Test func wrapComputedPropertyWithReturn() {
    let input = """
      var value: Int { return 42 }
      """
    let output = """
      var value: Int {
          return 42
      }
      """
    testFormatting(for: input, output, rule: .wrapPropertyBodies)
  }

  @Test func doesNotWrapAlreadyMultilineComputedProperty() {
    let input = """
      var bar: String {
          "bar"
      }
      """
    testFormatting(for: input, rule: .wrapPropertyBodies)
  }

  @Test func wrapStoredPropertyWithDidSet() {
    let input = """
      var value: Int = 0 { didSet { print("changed") } }
      """
    let output = """
      var value: Int = 0 {
          didSet { print("changed") }
      }
      """
    testFormatting(for: input, output, rule: .wrapPropertyBodies)
  }

  @Test func wrapStoredPropertyWithWillSet() {
    let input = """
      var value: Int = 0 { willSet { print("will change") } }
      """
    let output = """
      var value: Int = 0 {
          willSet { print("will change") }
      }
      """
    testFormatting(for: input, output, rule: .wrapPropertyBodies)
  }

  @Test func wrapStoredPropertyWithDidSetNoInitialValue() {
    let input = """
      var foo: Int { didSet { bar() } }
      """
    let output = """
      var foo: Int {
          didSet { bar() }
      }
      """
    testFormatting(for: input, output, rule: .wrapPropertyBodies)
  }

  @Test func wrapComputedPropertyInStruct() {
    let input = """
      struct Foo {
          var bar: String { "bar" }
      }
      """
    let output = """
      struct Foo {
          var bar: String {
              "bar"
          }
      }
      """
    testFormatting(for: input, output, rule: .wrapPropertyBodies)
  }

  @Test func wrapComputedPropertyWithGetterSetter() {
    let input = """
      var foo: Int {
          get { _foo }
          set { _foo = newValue }
      }
      """
    testFormatting(for: input, rule: .wrapPropertyBodies)
  }

  // MARK: - Functions (should NOT be wrapped by this rule)

  @Test func doesNotWrapFunction() {
    let input = """
      func foo() { print("bar") }
      """
    testFormatting(for: input, rule: .wrapPropertyBodies, exclude: [.wrapFunctionBodies])
  }

  @Test func doesNotWrapInit() {
    let input = """
      init() { value = 0 }
      """
    testFormatting(for: input, rule: .wrapPropertyBodies, exclude: [.wrapFunctionBodies])
  }

  @Test func doesNotWrapSubscript() {
    let input = """
      subscript(index: Int) -> Int { array[index] }
      """
    testFormatting(for: input, rule: .wrapPropertyBodies, exclude: [.wrapFunctionBodies])
  }

  // MARK: - Protocols (should NOT be wrapped)

  @Test func doesNotWrapComputedPropertyInProtocol() {
    let input = """
      protocol Expandable: ExpandableView {
          var expansionStateDidChange: ((Self) -> Void)? { get set }
      }
      """
    testFormatting(for: input, rule: .wrapPropertyBodies)
  }

  @Test func doesNotWrapComputedPropertyInProtocolWithClassConstraint() {
    let input = """
      protocol LayoutBacked: class {
          var layoutNode: LayoutNode? { get }
      }
      """
    testFormatting(for: input, rule: .wrapPropertyBodies)
  }
}
