@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseSelfNotTypeNameTests: RuleTesting {

  @Test func typeOfSelfReplaced() {
    assertFormatting(
      UseSelfNotTypeName.self,
      input: """
        final class Foo {
            func bar() {
                1️⃣type(of: self).baz()
            }
        }
        """,
      expected: """
        final class Foo {
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

  @Test func nonFinalClassNotChanged() {
    // A subclass instance has a dynamic type that `Self` does not name.
    assertFormatting(
      UseSelfNotTypeName.self,
      input: """
        class Foo {
            func bar() {
                type(of: self).baz()
            }
        }
        """,
      expected: """
        class Foo {
            func bar() {
                type(of: self).baz()
            }
        }
        """,
      findings: []
    )
  }

  @Test func protocolExtensionNotChanged() {
    // `Self` binds to the conforming type, which is not the dynamic type of a subclass instance.
    assertFormatting(
      UseSelfNotTypeName.self,
      input: """
        extension PersistableRecord {
            func update() {
                let name = type(of: self).databaseTableName
            }
        }
        """,
      expected: """
        extension PersistableRecord {
            func update() {
                let name = type(of: self).databaseTableName
            }
        }
        """,
      findings: []
    )
  }

  @Test func nestedStructInExtensionReplaced() {
    assertFormatting(
      UseSelfNotTypeName.self,
      input: """
        extension Foo {
            struct Inner {
                func bar() {
                    1️⃣type(of: self).baz()
                }
            }
        }
        """,
      expected: """
        extension Foo {
            struct Inner {
                func bar() {
                    Self.baz()
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "prefer 'Self' over 'type(of: self)'"),
      ]
    )
  }

  @Test func nestedClassInStructNotChanged() {
    assertFormatting(
      UseSelfNotTypeName.self,
      input: """
        struct Outer {
            class Inner {
                func bar() {
                    type(of: self).baz()
                }
            }
        }
        """,
      expected: """
        struct Outer {
            class Inner {
                func bar() {
                    type(of: self).baz()
                }
            }
        }
        """,
      findings: []
    )
  }

  @Test func actorReplaced() {
    assertFormatting(
      UseSelfNotTypeName.self,
      input: """
        actor Foo {
            func bar() {
                1️⃣type(of: self).baz()
            }
        }
        """,
      expected: """
        actor Foo {
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
      UseSelfNotTypeName.self,
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
      UseSelfNotTypeName.self,
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
      UseSelfNotTypeName.self,
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
