@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantClosureTests: RuleTesting {

  // MARK: - Conversions

  @Test func singleExpression() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let foo = 1️⃣{ "Foo" }()
        """,
      expected: """
        let foo = "Foo"
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly")
      ])
  }

  @Test func singleExpressionWithReturn() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let foo = 1️⃣{ return "Foo" }()
        """,
      expected: """
        let foo = "Foo"
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly")
      ])
  }

  @Test func multilineClosure() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        lazy var bar = 1️⃣{
            Bar()
        }()
        """,
      expected: """
        lazy var bar = Bar()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly")
      ])
  }

  @Test func multilineClosureWithReturn() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        lazy var bar = 1️⃣{
            return Bar()
        }()
        """,
      expected: """
        lazy var bar = Bar()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly")
      ])
  }

  @Test func multipleClosuresOnSeparateLines() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let foo = 1️⃣{ "Foo" }()
        let bar = 2️⃣{ "Bar" }()
        """,
      expected: """
        let foo = "Foo"
        let bar = "Bar"
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly"),
        FindingSpec("2️⃣", message: "remove immediately-invoked closure; use the expression directly"),
      ])
  }

  @Test func closureWithFunctionCallExpression() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let foo = 1️⃣{ Foo(bar: bar, baaz: baaz) }()
        """,
      expected: """
        let foo = Foo(bar: bar, baaz: baaz)
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly")
      ])
  }

  @Test func closureWithMemberAccess() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let x = 1️⃣{ someObject.property }()
        """,
      expected: """
        let x = someObject.property
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly")
      ])
  }

  @Test func closureWithNestedClosure() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        lazy var foo = 1️⃣{
            Foo(handle: { fatalError() })
        }()
        """,
      expected: """
        lazy var foo = Foo(handle: { fatalError() })
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly")
      ])
  }

  @Test func closureWithGenericTypes() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let foo: Foo<Bar> = 1️⃣{ DefaultFoo<Bar>() }()
        """,
      expected: """
        let foo: Foo<Bar> = DefaultFoo<Bar>()
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove immediately-invoked closure; use the expression directly")
      ])
  }

  // MARK: - No-ops

  @Test func closureNotCalled() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let foo = { "Foo" }
        """,
      expected: """
        let foo = { "Foo" }
        """)
  }

  @Test func emptyClosures() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let foo = {}()
        """,
      expected: """
        let foo = {}()
        """)
  }

  @Test func multiStatementClosure() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        lazy var quux = {
            print("hello world")
            return "quux"
        }()
        """,
      expected: """
        lazy var quux = {
            print("hello world")
            return "quux"
        }()
        """)
  }

  @Test func closureWithInToken() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        lazy var double = { () -> Double in
            100
        }()
        """,
      expected: """
        lazy var double = { () -> Double in
            100
        }()
        """)
  }

  @Test func closureWithParameters() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let x = { (a: Int) in a + 1 }(42)
        """,
      expected: """
        let x = { (a: Int) in a + 1 }(42)
        """)
  }

  @Test func closureWithCaptureList() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let x = { [weak self] in self?.value }()
        """,
      expected: """
        let x = { [weak self] in self?.value }()
        """)
  }

  @Test func closureThatCallsFatalError() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        lazy var foo: String = { fatalError("no default value") }()
        """,
      expected: """
        lazy var foo: String = { fatalError("no default value") }()
        """)
  }

  @Test func closureThatCallsPreconditionFailure() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        lazy var bar: String = { preconditionFailure("not set") }()
        """,
      expected: """
        lazy var bar: String = { preconditionFailure("not set") }()
        """)
  }

  @Test func multiStatementClosureSameLine() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        lazy var baaz = {
            print("Foo"); return baaz
        }()
        """,
      expected: """
        lazy var baaz = {
            print("Foo"); return baaz
        }()
        """)
  }

  @Test func closureWrappedInTry() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let x = try { return foo() }()
        """,
      expected: """
        let x = try { return foo() }()
        """)
  }

  @Test func closureWrappedInAwait() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let x = await { return foo() }()
        """,
      expected: """
        let x = await { return foo() }()
        """)
  }

  @Test func normalFunctionCallNotFlagged() {
    assertFormatting(
      RedundantClosure.self,
      input: """
        let x = foo()
        """,
      expected: """
        let x = foo()
        """)
  }
}
