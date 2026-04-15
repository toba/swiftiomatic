@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct WrapBodiesTests: RuleTesting {

  // MARK: - Guard statements

  @Test func guardReturnWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ return }
        """,
      expected: """
        guard let foo = bar else {
            return
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  @Test func guardReturnWithValueWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ return baz }
        """,
      expected: """
        guard let foo = bar else {
            return baz
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  @Test func emptyGuardBodyUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard let foo = bar else { }
        """,
      expected: """
        guard let foo = bar else { }
        """)
  }

  @Test func emptyGuardBodyNoSpaceUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard let foo = bar else {}
        """,
      expected: """
        guard let foo = bar else {}
        """)
  }

  @Test func guardAlreadyWrappedUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard let foo = bar else {
            return
        }
        """,
      expected: """
        guard let foo = bar else {
            return
        }
        """)
  }

  @Test func guardContinueWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard let foo = bar else 1️⃣{continue}
        """,
      expected: """
        guard let foo = bar else {
            continue
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  @Test func guardBodyWithClosingBraceOnNewlineWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard foo else 1️⃣{ return
        }
        """,
      expected: """
        guard foo else {
            return
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  // MARK: - If/else statements

  @Test func ifElseReturnsWrap() {
    assertFormatting(
      WrapBodies.self,
      input: """
        if foo 1️⃣{ return bar } else if baz 2️⃣{ return qux } else 3️⃣{ return quux }
        """,
      expected: """
        if foo {
            return bar
        } else if baz {
            return qux
        } else {
            return quux
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("3️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  @Test func ifElseBodiesWrap() {
    assertFormatting(
      WrapBodies.self,
      input: """
        if foo 1️⃣{ bar } else if baz 2️⃣{ qux } else 3️⃣{ quux }
        """,
      expected: """
        if foo {
            bar
        } else if baz {
            qux
        } else {
            quux
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("3️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  @Test func emptyIfElseBodiesUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        if foo { } else if baz { } else { }
        """,
      expected: """
        if foo { } else if baz { } else { }
        """)
  }

  @Test func alreadyWrappedIfElseUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        if foo {
            return bar
        } else {
            return baz
        }
        """,
      expected: """
        if foo {
            return bar
        } else {
            return baz
        }
        """)
  }

  // MARK: - Nested conditionals

  @Test func nestedGuardElseIfWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ if qux 2️⃣{ return quux } else 3️⃣{ return quuz } }
        """,
      expected: """
        guard let foo = bar else {
            if qux {
                return quux
            } else {
                return quuz
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("3️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  @Test func nestedGuardElseGuardWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ guard qux else 2️⃣{ return quux } }
        """,
      expected: """
        guard let foo = bar else {
            guard qux else {
                return quux
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  // MARK: - Indented conditionals

  @Test func indentedGuardWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        func test() {
            guard let foo = bar else 1️⃣{ return }
        }
        """,
      expected: """
        func test() {
            guard let foo = bar else {
                return
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  @Test func indentedIfElseWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        func test() {
            if foo 1️⃣{ return bar } else 2️⃣{ return baz }
        }
        """,
      expected: """
        func test() {
            if foo {
                return bar
            } else {
                return baz
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap conditional body onto a new line"),
        FindingSpec("2️⃣", message: "wrap conditional body onto a new line"),
      ])
  }

  // MARK: - Semicolon-delimited statements

  @Test func guardWithSemicolonDelimitedStatements() {
    assertFormatting(
      WrapBodies.self,
      input: """
        guard let foo = bar else 1️⃣{ var baz = 0; let boo = 1; fatalError() }
        """,
      expected: """
        guard let foo = bar else {
            var baz = 0; let boo = 1; fatalError()
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap conditional body onto a new line")])
  }

  // MARK: - Functions

  @Test func singleLineFunctionWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        func foo() 1️⃣{ print("bar") }
        """,
      expected: """
        func foo() {
            print("bar")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  @Test func functionWithReturnWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        func getValue() -> Int 1️⃣{ return 42 }
        """,
      expected: """
        func getValue() -> Int {
            return 42
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  @Test func alreadyMultilineFunctionUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        func foo() {
            print("bar")
        }
        """,
      expected: """
        func foo() {
            print("bar")
        }
        """)
  }

  @Test func emptyFunctionBodyUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        func foo() {}
        """,
      expected: """
        func foo() {}
        """)
  }

  @Test func functionWithSomeReturnTypeWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        func foo() -> some View 1️⃣{ Text("hello") }
        """,
      expected: """
        func foo() -> some View {
            Text("hello")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  // MARK: - Initializers

  @Test func singleLineInitWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        init() 1️⃣{ value = 0 }
        """,
      expected: """
        init() {
            value = 0
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  @Test func failableInitWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        init?() 1️⃣{ return nil }
        """,
      expected: """
        init?() {
            return nil
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  // MARK: - Subscripts

  @Test func singleLineSubscriptWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        subscript(index: Int) -> Int 1️⃣{ array[index] }
        """,
      expected: """
        subscript(index: Int) -> Int {
            array[index]
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  // MARK: - Function rule should NOT wrap

  @Test func closureNotWrapped() {
    assertFormatting(
      WrapBodies.self,
      input: """
        let closure = { print("hello") }
        """,
      expected: """
        let closure = { print("hello") }
        """)
  }

  @Test func closureAsArgumentNotWrapped() {
    assertFormatting(
      WrapBodies.self,
      input: """
        array.map { $0 * 2 }
        """,
      expected: """
        array.map { $0 * 2 }
        """)
  }

  @Test func protocolFunctionDeclarationNotWrapped() {
    assertFormatting(
      WrapBodies.self,
      input: """
        protocol Foo {
            func bar() -> String
        }
        """,
      expected: """
        protocol Foo {
            func bar() -> String
        }
        """)
  }

  @Test func protocolSubscriptDeclarationNotWrapped() {
    assertFormatting(
      WrapBodies.self,
      input: """
        protocol Foo {
            subscript(index: Int) -> Int { get }
        }
        """,
      expected: """
        protocol Foo {
            subscript(index: Int) -> Int { get }
        }
        """)
  }

  // MARK: - Indented function context

  @Test func functionInClassWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        class Foo {
            func bar() 1️⃣{ print("baz") }
        }
        """,
      expected: """
        class Foo {
            func bar() {
                print("baz")
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  // MARK: - For loops

  @Test func forLoopWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        for foo in bar 1️⃣{ print(foo) }
        """,
      expected: """
        for foo in bar {
            print(foo)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  @Test func forLoopAlreadyWrappedUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        for foo in bar {
            print(foo)
        }
        """,
      expected: """
        for foo in bar {
            print(foo)
        }
        """)
  }

  @Test func emptyForLoopUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        for foo in bar { }
        """,
      expected: """
        for foo in bar { }
        """)
  }

  @Test func indentedForLoopWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        func test() {
            for foo in bar 1️⃣{ print(foo) }
        }
        """,
      expected: """
        func test() {
            for foo in bar {
                print(foo)
            }
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  @Test func forLoopWithWhereWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        for foo in bar where foo > 0 1️⃣{ print(foo) }
        """,
      expected: """
        for foo in bar where foo > 0 {
            print(foo)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  // MARK: - While loops

  @Test func whileLoopWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        while let foo = bar.next() 1️⃣{ print(foo) }
        """,
      expected: """
        while let foo = bar.next() {
            print(foo)
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  @Test func whileLoopAlreadyWrappedUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        while condition {
            doSomething()
        }
        """,
      expected: """
        while condition {
            doSomething()
        }
        """)
  }

  // MARK: - Repeat-while loops

  @Test func repeatWhileLoopWraps() {
    assertFormatting(
      WrapBodies.self,
      input: """
        repeat 1️⃣{ print(foo) } while condition()
        """,
      expected: """
        repeat {
            print(foo)
        } while condition()
        """,
      findings: [FindingSpec("1️⃣", message: "wrap loop body onto a new line")])
  }

  @Test func repeatWhileAlreadyWrappedUnchanged() {
    assertFormatting(
      WrapBodies.self,
      input: """
        repeat {
            print(foo)
        } while condition()
        """,
      expected: """
        repeat {
            print(foo)
        } while condition()
        """)
  }

  // MARK: - Nested loops

  @Test func nestedForLoopsWrap() {
    assertFormatting(
      WrapBodies.self,
      input: """
        for x in xs 1️⃣{ for y in ys 2️⃣{ print(x, y) } }
        """,
      expected: """
        for x in xs {
            for y in ys {
                print(x, y)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "wrap loop body onto a new line"),
        FindingSpec("2️⃣", message: "wrap loop body onto a new line"),
      ])
  }

  // MARK: - Computed properties

  @Test func singleLineComputedPropertyWraps() {
    assertFormatting(
      WrapBodies.self,
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
      WrapBodies.self,
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
      WrapBodies.self,
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
      WrapBodies.self,
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
      WrapBodies.self,
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
      WrapBodies.self,
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

  // MARK: - Indented property context

  @Test func computedPropertyInStructWraps() {
    assertFormatting(
      WrapBodies.self,
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

  // MARK: - Already wrapped properties

  @Test func computedPropertyWithGetterSetterUnchanged() {
    assertFormatting(
      WrapBodies.self,
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

  // MARK: - Property rule should NOT wrap

  @Test func functionNotWrappedByPropertyRule() {
    // This test verifies computed property rule doesn't affect functions.
    // With the merged rule, functions DO get wrapped by the function visitor.
    // So this test is adapted: a single-line function IS wrapped by WrapBodies.
    assertFormatting(
      WrapBodies.self,
      input: """
        func foo() 1️⃣{ print("bar") }
        """,
      expected: """
        func foo() {
            print("bar")
        }
        """,
      findings: [FindingSpec("1️⃣", message: "wrap function body onto a new line")])
  }

  @Test func protocolPropertyNotWrapped() {
    assertFormatting(
      WrapBodies.self,
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
      WrapBodies.self,
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
