@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapPropertyBodiesTests: RuleTesting {

  // MARK: - Computed properties

  @Test func singleLineComputedPropertyWraps() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        var bar: String 1️⃣{ "bar" }
        """,
      expected: """
        var bar: String {
            "bar"
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap property body onto a new line")])
  }

  @Test func computedPropertyWithReturnWraps() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        var value: Int 1️⃣{ return 42 }
        """,
      expected: """
        var value: Int {
            return 42
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap property body onto a new line")])
  }

  @Test func alreadyMultilineComputedPropertyUnchanged() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        var bar: String {
            "bar"
        }
        """,
      expected: """
        var bar: String {
            "bar"
        }
        """)
  }

  // MARK: - Property observers

  @Test func storedPropertyWithDidSetWraps() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        var value: Int = 0 1️⃣{ didSet { print("changed") } }
        """,
      expected: """
        var value: Int = 0 {
            didSet { print("changed") }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap property body onto a new line")])
  }

  @Test func storedPropertyWithWillSetWraps() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        var value: Int = 0 1️⃣{ willSet { print("will change") } }
        """,
      expected: """
        var value: Int = 0 {
            willSet { print("will change") }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap property body onto a new line")])
  }

  @Test func propertyWithDidSetNoInitialValueWraps() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        var foo: Int 1️⃣{ didSet { bar() } }
        """,
      expected: """
        var foo: Int {
            didSet { bar() }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap property body onto a new line")])
  }

  // MARK: - Indented context

  @Test func computedPropertyInStructWraps() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        struct Foo {
            var bar: String 1️⃣{ "bar" }
        }
        """,
      expected: """
        struct Foo {
            var bar: String {
                "bar"
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap property body onto a new line")])
  }

  // MARK: - Already wrapped

  @Test func computedPropertyWithGetterSetterUnchanged() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        var foo: Int {
            get { _foo }
            set { _foo = newValue }
        }
        """,
      expected: """
        var foo: Int {
            get { _foo }
            set { _foo = newValue }
        }
        """)
  }

  // MARK: - Should NOT wrap

  @Test func functionNotWrapped() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        func foo() { print("bar") }
        """,
      expected: """
        func foo() { print("bar") }
        """)
  }

  @Test func protocolPropertyNotWrapped() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        protocol Expandable: ExpandableView {
            var expansionStateDidChange: ((Self) -> Void)? { get set }
        }
        """,
      expected: """
        protocol Expandable: ExpandableView {
            var expansionStateDidChange: ((Self) -> Void)? { get set }
        }
        """)
  }

  @Test func protocolPropertyGetOnlyNotWrapped() {
    assertFormatting(
      WrapPropertyBodies.self,
      input: """
        protocol LayoutBacked: AnyObject {
            var layoutNode: LayoutNode? { get }
        }
        """,
      expected: """
        protocol LayoutBacked: AnyObject {
            var layoutNode: LayoutNode? { get }
        }
        """)
  }
}
