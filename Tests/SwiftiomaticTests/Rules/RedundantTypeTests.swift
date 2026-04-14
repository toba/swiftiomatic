@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantTypeTests: RuleTesting {
  @Test func constructorCall() {
    assertLint(
      RedundantType.self,
      """
      let x1️⃣: Foo = Foo()
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Foo'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func constructorCallWithArgs() {
    assertLint(
      RedundantType.self,
      """
      let x1️⃣: Foo = Foo(bar: 1)
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Foo'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func boolLiteral() {
    assertLint(
      RedundantType.self,
      """
      let flag1️⃣: Bool = true
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Bool'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func stringLiteral() {
    assertLint(
      RedundantType.self,
      """
      let name1️⃣: String = "hello"
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'String'; it is obvious from the initializer"),
      ]
    )
  }

  @Test func intLiteralNotFlagged() {
    assertLint(
      RedundantType.self,
      """
      let x: Int = 42
      """,
      findings: []
    )
  }

  @Test func floatLiteralNotFlagged() {
    assertLint(
      RedundantType.self,
      """
      let x: Double = 3.14
      """,
      findings: []
    )
  }

  @Test func differentTypeNotFlagged() {
    assertLint(
      RedundantType.self,
      """
      let x: FooProtocol = Foo()
      """,
      findings: []
    )
  }

  @Test func noTypeAnnotationNotFlagged() {
    assertLint(
      RedundantType.self,
      """
      let x = Foo()
      """,
      findings: []
    )
  }

  @Test func noInitializerNotFlagged() {
    assertLint(
      RedundantType.self,
      """
      var x: Foo?
      """,
      findings: []
    )
  }

  @Test func functionCallNotFlagged() {
    assertLint(
      RedundantType.self,
      """
      let x: String = makeString()
      """,
      findings: []
    )
  }

  @Test func explicitInitCall() {
    assertLint(
      RedundantType.self,
      """
      let x1️⃣: Foo = Foo.init(bar: 1)
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant type annotation 'Foo'; it is obvious from the initializer"),
      ]
    )
  }
}
