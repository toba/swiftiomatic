@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantTypeTests: RuleTesting {
  @Test func constructorCall() {
    assertFormatting(
      RedundantType.self,
      input: """
        let x1️⃣: Foo = Foo()
        """,
      expected: """
        let x = Foo()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Foo'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func constructorCallWithArgs() {
    assertFormatting(
      RedundantType.self,
      input: """
        let x1️⃣: Foo = Foo(bar: 1)
        """,
      expected: """
        let x = Foo(bar: 1)
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Foo'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func boolLiteral() {
    assertFormatting(
      RedundantType.self,
      input: """
        let flag1️⃣: Bool = true
        """,
      expected: """
        let flag = true
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Bool'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func stringLiteral() {
    assertFormatting(
      RedundantType.self,
      input: """
        let name1️⃣: String = "hello"
        """,
      expected: """
        let name = "hello"
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'String'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func intLiteralNotFlagged() {
    assertFormatting(
      RedundantType.self,
      input: """
        let x: Int = 42
        """,
      expected: """
        let x: Int = 42
        """,
      findings: []
    )
  }

  @Test func floatLiteralNotFlagged() {
    assertFormatting(
      RedundantType.self,
      input: """
        let x: Double = 3.14
        """,
      expected: """
        let x: Double = 3.14
        """,
      findings: []
    )
  }

  @Test func differentTypeNotFlagged() {
    assertFormatting(
      RedundantType.self,
      input: """
        let x: FooProtocol = Foo()
        """,
      expected: """
        let x: FooProtocol = Foo()
        """,
      findings: []
    )
  }

  @Test func noTypeAnnotationNotFlagged() {
    assertFormatting(
      RedundantType.self,
      input: """
        let x = Foo()
        """,
      expected: """
        let x = Foo()
        """,
      findings: []
    )
  }

  @Test func noInitializerNotFlagged() {
    assertFormatting(
      RedundantType.self,
      input: """
        var x: Foo?
        """,
      expected: """
        var x: Foo?
        """,
      findings: []
    )
  }

  @Test func functionCallNotFlagged() {
    assertFormatting(
      RedundantType.self,
      input: """
        let x: String = makeString()
        """,
      expected: """
        let x: String = makeString()
        """,
      findings: []
    )
  }

  @Test func explicitInitCall() {
    assertFormatting(
      RedundantType.self,
      input: """
        let x1️⃣: Foo = Foo.init(bar: 1)
        """,
      expected: """
        let x = Foo.init(bar: 1)
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Foo'; it is obvious from the initializer"),
      ]
    )
  }

  // MARK: - Adapted from SwiftFormat

  @Test func varRedundantTypeRemoval() {
    assertFormatting(
      RedundantType.self,
      input: """
        var view1️⃣: UIView = UIView()
        """,
      expected: """
        var view = UIView()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'UIView'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func varNonRedundantTypeDoesNothing() {
    assertFormatting(
      RedundantType.self,
      input: """
        var view: UIView = UINavigationBar()
        """,
      expected: """
        var view: UIView = UINavigationBar()
        """,
      findings: []
    )
  }

  @Test func letNonRedundantTypeDoesNothing() {
    assertFormatting(
      RedundantType.self,
      input: """
        let view: UIView = UINavigationBar()
        """,
      expected: """
        let view: UIView = UINavigationBar()
        """,
      findings: []
    )
  }

  @Test func typeNoRedundancyDoesNothing() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo: Bar = 5
        """,
      expected: """
        let foo: Bar = 5
        """,
      findings: []
    )
  }

  @Test func nonRedundantTernaryConditionTypeNotRemoved() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo: Bar = Bar.baz() ? .bar1 : .bar2
        """,
      expected: """
        let foo: Bar = Bar.baz() ? .bar1 : .bar2
        """,
      findings: []
    )
  }

  @Test func redundantTypeWithLiterals() {
    assertFormatting(
      RedundantType.self,
      input: """
        let a11️⃣: Bool = true
        let a22️⃣: Bool = false
        let b13️⃣: String = "foo"
        let c1: Int = 1
        let d1: Double = 3.14
        """,
      expected: """
        let a1 = true
        let a2 = false
        let b1 = "foo"
        let c1: Int = 1
        let d1: Double = 3.14
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Bool'; it is obvious from the initializer"),
        FindingSpec("2️⃣", message: "remove redundant type annotation 'Bool'; it is obvious from the initializer"),
        FindingSpec("3️⃣", message: "remove redundant type annotation 'String'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func redundantTypePreservesLiteralRepresentableTypes() {
    assertFormatting(
      RedundantType.self,
      input: """
        let a: MyBoolRepresentable = true
        let b: MyStringRepresentable = "foo"
        """,
      expected: """
        let a: MyBoolRepresentable = true
        let b: MyStringRepresentable = "foo"
        """,
      findings: []
    )
  }

  @Test func classTwoVariablesNoRedundantTypeDoesNothing() {
    assertFormatting(
      RedundantType.self,
      input: """
        final class LGWebSocketClient {
          var webSocket: WebSocketLibraryProtocol
          var timeoutIntervalForRequest: TimeInterval = LGCoreKitConstants.websocketTimeOutTimeInterval
        }
        """,
      expected: """
        final class LGWebSocketClient {
          var webSocket: WebSocketLibraryProtocol
          var timeoutIntervalForRequest: TimeInterval = LGCoreKitConstants.websocketTimeOutTimeInterval
        }
        """,
      findings: []
    )
  }

  @Test func redundantTypeRemovedIfValueOnNextLine() {
    assertFormatting(
      RedundantType.self,
      input: """
        let view1️⃣: UIView
            = UIView()
        """,
      expected: """
        let view
            = UIView()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'UIView'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func redundantTypeRemovedIfValueOnNextLine2() {
    assertFormatting(
      RedundantType.self,
      input: """
        let view1️⃣: UIView =
            UIView()
        """,
      expected: """
        let view =
            UIView()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'UIView'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func staticMethodCallNotFlagged() {
    // SwiftFormat removes this, but we don't — Bar.baz() is a static method call,
    // not a constructor. The type annotation tells the compiler the return type.
    assertFormatting(
      RedundantType.self,
      input: """
        func test() {
          let foo: Bar = Bar.baz()
          baz ? bar2() : bar2()
        }
        """,
      expected: """
        func test() {
          let foo: Bar = Bar.baz()
          baz ? bar2() : bar2()
        }
        """,
      findings: []
    )
  }

  @Test func varRedundantArrayTypeRemoval() {
    assertFormatting(
      RedundantType.self,
      input: """
        var foo1️⃣: [String] = [String]()
        """,
      expected: """
        var foo = [String]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation '[String]'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func varRedundantDictionaryTypeRemoval() {
    assertFormatting(
      RedundantType.self,
      input: """
        var foo1️⃣: [String: Int] = [String: Int]()
        """,
      expected: """
        var foo = [String: Int]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation '[String: Int]'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func letRedundantGenericTypeRemoval() {
    assertFormatting(
      RedundantType.self,
      input: """
        let relay1️⃣: BehaviourRelay<Int?> = BehaviourRelay<Int?>(value: nil)
        """,
      expected: """
        let relay = BehaviourRelay<Int?>(value: nil)
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'BehaviourRelay<Int?>'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func noRemoveRedundantTypeIfVoid() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo: Void = Void()
        """,
      expected: """
        let foo: Void = Void()
        """,
      findings: []
    )
  }

  @Test func noRemoveRedundantTypeIfVoidTuple() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo: () = ()
        """,
      expected: """
        let foo: () = ()
        """,
      findings: []
    )
  }

  @Test func redundantTypeWithIfExpression() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo1️⃣: Foo = if condition {
          Foo("foo")
        } else {
          Foo("bar")
        }
        """,
      expected: """
        let foo = if condition {
          Foo("foo")
        } else {
          Foo("bar")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Foo'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func preservesNonRedundantTypeWithIfExpression() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo: Foo = if condition {
          Foo("foo")
        } else {
          FooSubclass("bar")
        }
        """,
      expected: """
        let foo: Foo = if condition {
          Foo("foo")
        } else {
          FooSubclass("bar")
        }
        """,
      findings: []
    )
  }

  // MARK: - Additional SwiftFormat adapted tests

  @Test func redundantTypeRemovalWithComment() {
    assertFormatting(
      RedundantType.self,
      input: """
        var view1️⃣: UIView /* view */ = UIView()
        """,
      expected: """
        var view /* view */ = UIView()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'UIView'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func redundantTypeRemovalWithComment2() {
    assertFormatting(
      RedundantType.self,
      input: """
        var view1️⃣: UIView = /* view */ UIView()
        """,
      expected: """
        var view = /* view */ UIView()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'UIView'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func noRemoveRedundantTypeIfVoidArray() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo: [Void] = [Void]()
        """,
      expected: """
        let foo: [Void] = [Void]()
        """,
      findings: []
    )
  }

  @Test func noRemoveRedundantTypeIfOptionalVoid() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo: Void? = Void?.none
        """,
      expected: """
        let foo: Void? = Void?.none
        """,
      findings: []
    )
  }

  @Test func redundantTypeWithStringInterpolation() {
    assertFormatting(
      RedundantType.self,
      input: """
        let b1️⃣: String = "\\(something)"
        """,
      expected: """
        let b = "\\(something)"
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'String'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func redundantTypeWithSwitchExpression() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo1️⃣: Foo = switch condition {
        case true:
          Foo("foo")
        case false:
          Foo("bar")
        }
        """,
      expected: """
        let foo = switch condition {
        case true:
          Foo("foo")
        case false:
          Foo("bar")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Foo'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func preservesNonRedundantTypeWithSwitchExpression() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo: Foo = switch condition {
        case true:
          Foo("foo")
        case false:
          FooSubclass("bar")
        }
        """,
      expected: """
        let foo: Foo = switch condition {
        case true:
          Foo("foo")
        case false:
          FooSubclass("bar")
        }
        """,
      findings: []
    )
  }

  @Test func redundantTypeWithLiteralsInIfExpression() {
    assertFormatting(
      RedundantType.self,
      input: """
        let foo1️⃣: String = if condition {
          "foo"
        } else {
          "bar"
        }
        """,
      expected: """
        let foo = if condition {
          "foo"
        } else {
          "bar"
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'String'; it is obvious from the initializer"),
      ]
    )
  }
}
