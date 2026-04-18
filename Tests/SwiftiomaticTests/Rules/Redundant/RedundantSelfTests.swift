@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantSelfTests: RuleTesting {

  // MARK: - Basic Removal

  @Test func removeRedundantSelfInMethod() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int = 0
            func baz() {
                1️⃣self.bar = 5
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int = 0
            func baz() {
                bar = 5
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfMethodCall() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            func bar() {}
            func baz() {
                1️⃣self.bar()
            }
        }
        """,
      expected: """
        struct Foo {
            func bar() {}
            func baz() {
                bar()
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfInsideStringInterpolation() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: String?
            func baz() {
                print("\\(1️⃣self.bar)")
            }
        }
        """,
      expected: """
        class Foo {
            var bar: String?
            func baz() {
                print("\\(bar)")
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfInsideClassInit() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar = 5
            init() { 1️⃣self.bar = 6 }
        }
        """,
      expected: """
        class Foo {
            var bar = 5
            init() { bar = 6 }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfInsideSwitch() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: String = ""
            func baz() {
                switch 1️⃣self.bar {
                case "foo":
                    2️⃣self.bar = "baz"
                default:
                    break
                }
            }
        }
        """,
      expected: """
        struct Foo {
            var bar: String = ""
            func baz() {
                switch bar {
                case "foo":
                    bar = "baz"
                default:
                    break
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix"),
        FindingSpec("2️⃣", message: "remove redundant 'self.' prefix"),
      ])
  }

  @Test func removeRedundantSelfFromComputedVar() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            var baz: Int { return 1️⃣self.bar }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            var baz: Int { return bar }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfFromVarSetter() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            var baz: Int {
                get { return 1️⃣self.bar }
                set { 2️⃣self.bar = newValue }
            }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            var baz: Int {
                get { return bar }
                set { bar = newValue }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix"),
        FindingSpec("2️⃣", message: "remove redundant 'self.' prefix"),
      ])
  }

  @Test func removeRedundantSelfFromUnusedArgument() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var baz: Int = 0
            func foo(bar _: Int) { 1️⃣self.baz = 5 }
        }
        """,
      expected: """
        struct Foo {
            var baz: Int = 0
            func foo(bar _: Int) { baz = 5 }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfMatchingUnusedArgument() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            func foo(bar _: Int) { 1️⃣self.bar = 5 }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            func foo(bar _: Int) { bar = 5 }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfInDidSet() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            var baz: Int = 0 {
                didSet { 1️⃣self.bar = baz }
            }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            var baz: Int = 0 {
                didSet { bar = baz }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  // MARK: - Preservations (shadowing)

  @Test func noRemoveSelfForArgument() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            func foo(bar: Int) { self.bar = bar }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            func foo(bar: Int) { self.bar = bar }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfForLocalVariable() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            func foo() {
                var bar = self.bar
                bar += 1
            }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            func foo() {
                var bar = self.bar
                bar += 1
            }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfForRenamedArgument() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var baz: Int = 0
            func foo(bar baz: Int) { self.baz = baz }
        }
        """,
      expected: """
        struct Foo {
            var baz: Int = 0
            func foo(bar baz: Int) { self.baz = baz }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfForErrorInCatch() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var error: Error?
            func bar() {
                do {} catch { self.error = error }
            }
        }
        """,
      expected: """
        class Foo {
            var error: Error?
            func bar() {
                do {} catch { self.error = error }
            }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfForNewValueInSet() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var newValue: Int = 0
            var bar: Int {
                get { return 0 }
                set { self.newValue = newValue }
            }
        }
        """,
      expected: """
        class Foo {
            var newValue: Int = 0
            var bar: Int {
                get { return 0 }
                set { self.newValue = newValue }
            }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfForCustomNewValueInWillSet() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var n00b: Int = 0
            var bar: Int = 0 {
                willSet(n00b) { self.n00b = n00b }
            }
        }
        """,
      expected: """
        struct Foo {
            var n00b: Int = 0
            var bar: Int = 0 {
                willSet(n00b) { self.n00b = n00b }
            }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfForOldValueInDidSet() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var oldValue: Int = 0
            var bar: Int = 0 {
                didSet { self.oldValue = oldValue }
            }
        }
        """,
      expected: """
        struct Foo {
            var oldValue: Int = 0
            var bar: Int = 0 {
                didSet { self.oldValue = oldValue }
            }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfForIndexVarInFor() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var item: Int = 0
            func bar() {
                for item in [1, 2, 3] { self.item = item }
            }
        }
        """,
      expected: """
        struct Foo {
            var item: Int = 0
            func bar() {
                for item in [1, 2, 3] { self.item = item }
            }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfForKeyValueTupleInFor() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var key: String = ""
            var value: Int = 0
            func bar() {
                for (key, value) in dict { self.key = key; self.value = value }
            }
        }
        """,
      expected: """
        struct Foo {
            var key: String = ""
            var value: Int = 0
            func bar() {
                for (key, value) in dict { self.key = key; self.value = value }
            }
        }
        """,
      findings: [])
  }

  // MARK: - self.init Preservation

  @Test func noRemoveSelfBeforeInit() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            convenience init() { self.init(5) }
        }
        """,
      expected: """
        class Foo {
            convenience init() { self.init(5) }
        }
        """,
      findings: [])
  }

  // MARK: - Closures in Value Types

  @Test func removeRedundantSelfInClosureInStruct() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            func baz() {
                someFunc {
                    1️⃣self.bar = 5
                }
            }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            func baz() {
                someFunc {
                    bar = 5
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfInClosureInEnum() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        enum Foo {
            var bar: Int { return 0 }
            func baz() {
                someFunc {
                    print(1️⃣self.bar)
                }
            }
        }
        """,
      expected: """
        enum Foo {
            var bar: Int { return 0 }
            func baz() {
                someFunc {
                    print(bar)
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  // MARK: - Closures in Reference Types

  @Test func noRemoveClosureSelfInClass() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { self.bar = 5 }
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { self.bar = 5 }
            }
        }
        """,
      findings: [])
  }

  @Test func removeRedundantSelfInClosureWithExplicitCapture() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [self] in
                    1️⃣self.bar = 5
                }
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [self] in
                    bar = 5
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfInClosureWithUnownedCapture() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [unowned self] in
                    1️⃣self.bar = 5
                }
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [unowned self] in
                    bar = 5
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func noRemoveSelfInClosureWithWeakCapture() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [weak self] in
                    self?.bar = 5
                }
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [weak self] in
                    self?.bar = 5
                }
            }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfInNestedClosureWithoutCapture() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [self] in
                    1️⃣self.bar = 5
                    otherFunc {
                        self.bar = 6
                    }
                }
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [self] in
                    bar = 5
                    otherFunc {
                        self.bar = 6
                    }
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func removeRedundantSelfInNestedClosureWithCapture() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc {
                    self.bar = 5
                    otherFunc { [self] in
                        1️⃣self.bar = 6
                    }
                }
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc {
                    self.bar = 5
                    otherFunc { [self] in
                        bar = 6
                    }
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func closureParameterShadowsProperty() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [self] bar in
                    self.bar = bar
                }
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int = 0
            func baz() {
                someFunc { [self] bar in
                    self.bar = bar
                }
            }
        }
        """,
      findings: [])
  }

  // MARK: - Lazy Var

  @Test func noRemoveSelfFromLazyVarInClass() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int = 0
            lazy var baz = self.bar
        }
        """,
      expected: """
        class Foo {
            var bar: Int = 0
            lazy var baz = self.bar
        }
        """,
      findings: [])
  }

  @Test func removeRedundantSelfFromLazyVarInStruct() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            lazy var baz = 1️⃣self.bar
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            lazy var baz = bar
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  // MARK: - Getter Recursion

  @Test func noRemoveSelfInOwnGetter() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar: Int {
                return self.bar
            }
        }
        """,
      expected: """
        class Foo {
            var bar: Int {
                return self.bar
            }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfInOwnExplicitGetter() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int {
                get { return self.bar }
                set { }
            }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int {
                get { return self.bar }
                set { }
            }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfInOwnSetter() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int {
                get { return 0 }
                set { self.bar = newValue }
            }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int {
                get { return 0 }
                set { self.bar = newValue }
            }
        }
        """,
      findings: [])
  }

  @Test func removeRedundantSelfForDifferentPropertyInGetter() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var x: Int = 0
            var bar: Int { return 1️⃣self.x }
        }
        """,
      expected: """
        struct Foo {
            var x: Int = 0
            var bar: Int { return x }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  // MARK: - Comma-Delimited Local Variables

  @Test func noRemoveSelfForCommaDelimitedLocalVariables() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var foo: Int = 0
            var bar: Int = 0
            func baz() { let foo = self.foo, bar = self.bar }
        }
        """,
      expected: """
        struct Foo {
            var foo: Int = 0
            var bar: Int = 0
            func baz() { let foo = self.foo, bar = self.bar }
        }
        """,
      findings: [])
  }

  @Test func noRemoveSelfForTupleAssignedVariables() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            var baz: Int = 0
            func qux() { let (bar, baz) = (self.bar, self.baz) }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            var baz: Int = 0
            func qux() { let (bar, baz) = (self.bar, self.baz) }
        }
        """,
      findings: [])
  }

  // MARK: - Guard/If Let Scoping

  @Test func noRemoveSelfForVarCreatedInGuardScope() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var bar: Int = 0
            func baz() {
                guard let bar = someOptional else { return }
                let x = self.bar
            }
        }
        """,
      expected: """
        struct Foo {
            var bar: Int = 0
            func baz() {
                guard let bar = someOptional else { return }
                let x = self.bar
            }
        }
        """,
      findings: [])
  }

  // MARK: - Nested Functions

  @Test func noRemoveSelfWhenNestedFunctionShadows() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            func bar() {}
            func baz() {
                func bar() {}
                self.bar()
            }
        }
        """,
      expected: """
        struct Foo {
            func bar() {}
            func baz() {
                func bar() {}
                self.bar()
            }
        }
        """,
      findings: [])
  }

  // MARK: - Outside Type Body

  @Test func noRemoveSelfOutsideTypeBody() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        func foo() { self.bar() }
        """,
      expected: """
        func foo() { self.bar() }
        """,
      findings: [])
  }

  // MARK: - Multiple Removals

  @Test func multipleRedundantSelf() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            var x: Int = 0
            var y: Int = 0
            func update() {
                1️⃣self.x = 1
                2️⃣self.y = 2
                print(3️⃣self.x + 4️⃣self.y)
            }
        }
        """,
      expected: """
        struct Foo {
            var x: Int = 0
            var y: Int = 0
            func update() {
                x = 1
                y = 2
                print(x + y)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix"),
        FindingSpec("2️⃣", message: "remove redundant 'self.' prefix"),
        FindingSpec("3️⃣", message: "remove redundant 'self.' prefix"),
        FindingSpec("4️⃣", message: "remove redundant 'self.' prefix"),
      ])
  }

  // MARK: - Extension

  @Test func removeRedundantSelfInExtensionMethod() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        extension Foo {
            func bar() {
                1️⃣self.baz()
            }
        }
        """,
      expected: """
        extension Foo {
            func bar() {
                baz()
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }

  @Test func noRemoveSelfInClosureInExtension() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        extension Foo {
            func bar() {
                someFunc { self.baz() }
            }
        }
        """,
      expected: """
        extension Foo {
            func bar() {
                someFunc { self.baz() }
            }
        }
        """,
      findings: [])
  }

  // MARK: - Standalone Self

  @Test func noRemoveStandaloneSelf() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        struct Foo {
            func bar() {
                doSomething(with: self)
            }
        }
        """,
      expected: """
        struct Foo {
            func bar() {
                doSomething(with: self)
            }
        }
        """,
      findings: [])
  }

  // MARK: - Nested Types

  @Test func nestedTypeHasOwnScope() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Outer {
            var x = 1
            func foo() {
                1️⃣self.x = 2
                class Inner {
                    var y = 1
                    func bar() {
                        2️⃣self.y = 2
                    }
                }
            }
        }
        """,
      expected: """
        class Outer {
            var x = 1
            func foo() {
                x = 2
                class Inner {
                    var y = 1
                    func bar() {
                        y = 2
                    }
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix"),
        FindingSpec("2️⃣", message: "remove redundant 'self.' prefix"),
      ])
  }

  // MARK: - Catch With Explicit Binding

  @Test func noRemoveSelfForExplicitCatchBinding() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var err: Error?
            func bar() {
                do {} catch let err {
                    self.err = err
                }
            }
        }
        """,
      expected: """
        class Foo {
            var err: Error?
            func bar() {
                do {} catch let err {
                    self.err = err
                }
            }
        }
        """,
      findings: [])
  }

  // MARK: - didSet Self-reference (not recursion)

  @Test func removeRedundantSelfReferringSamePropertyInDidSet() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        class Foo {
            var bar = false {
                didSet {
                    1️⃣self.bar = !2️⃣self.bar
                }
            }
        }
        """,
      expected: """
        class Foo {
            var bar = false {
                didSet {
                    bar = !bar
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix"),
        FindingSpec("2️⃣", message: "remove redundant 'self.' prefix"),
      ])
  }

  // MARK: - Actors

  @Test func removeRedundantSelfInActorMethod() {
    assertFormatting(
      RedundantSelf.self,
      input: """
        actor Foo {
            var bar: Int = 0
            func baz() {
                1️⃣self.bar = 5
            }
        }
        """,
      expected: """
        actor Foo {
            var bar: Int = 0
            func baz() {
                bar = 5
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'self.' prefix")
      ])
  }
}
