@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferSelfTypeTests: RuleTesting {

  @Test func typeOfSelfReplaced() {
    assertFormatting(
      PreferSelfType.self,
      input: """
        class Foo {
            func bar() {
                1️⃣type(of: self).baz()
            }
        }
        """,
      expected: """
        class Foo {
            func bar() {
                Self.baz()
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'Self' over 'type(of: self)'"),
      ]
    )
  }

  @Test func swiftTypeOfSelfReplaced() {
    assertFormatting(
      PreferSelfType.self,
      input: """
        struct Foo {
            func bar() {
                print(1️⃣Swift.type(of: self).baz)
            }
        }
        """,
      expected: """
        struct Foo {
            func bar() {
                print(Self.baz)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'Self' over 'type(of: self)'"),
      ]
    )
  }

  @Test func nonSelfArgumentNotChanged() {
    assertFormatting(
      PreferSelfType.self,
      input: """
        class A {
            func foo(param: B) {
                type(of: param).bar()
            }
        }
        class C {
            func foo() {
                print(type(of: self))
            }
        }
        """,
      expected: """
        class A {
            func foo(param: B) {
                type(of: param).bar()
            }
        }
        class C {
            func foo() {
                print(type(of: self))
            }
        }
        """,
      findings: []
    )
  }

  @Test func topLevelTypeOfSelfNotChanged() {
    // Outside any type declaration, `Self` is not a valid replacement.
    assertFormatting(
      PreferSelfType.self,
      input: """
        let t = type(of: self)
        """,
      expected: """
        let t = type(of: self)
        """,
      findings: []
    )
  }
}
