@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantStaticSelfTests: RuleTesting {
  @Test func staticMethod() {
    assertLint(
      RedundantStaticSelf.self,
      """
      struct Foo {
        static let value = 42
        static func make() -> Foo {
          print(1️⃣Self.value)
          return Foo()
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  @Test func staticComputedProperty() {
    assertLint(
      RedundantStaticSelf.self,
      """
      struct Foo {
        static let x = 1
        static var doubled: Int {
          1️⃣Self.x * 2
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  @Test func instanceMethodNotFlagged() {
    assertLint(
      RedundantStaticSelf.self,
      """
      struct Foo {
        static let value = 42
        func bar() {
          print(Self.value)
        }
      }
      """,
      findings: []
    )
  }

  @Test func topLevelNotFlagged() {
    assertLint(
      RedundantStaticSelf.self,
      """
      let x = Self.value
      """,
      findings: []
    )
  }

  @Test func nonStaticFunctionNotFlagged() {
    assertLint(
      RedundantStaticSelf.self,
      """
      class Foo {
        class func bar() {
          print(1️⃣Self.value)
        }
        static let value = 1
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }
}
