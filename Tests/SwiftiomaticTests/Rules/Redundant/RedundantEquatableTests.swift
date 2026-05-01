@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantEquatableTests: RuleTesting {

  // MARK: - Conversions

  @Test func removeSimpleEquatableOnStruct() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            1️⃣static func ==(lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
                    && lhs.baaz == rhs.baaz
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove hand-written '==' operator; compiler-synthesized Equatable conformance is equivalent")
      ])
  }

  @Test func removeEquatableWithHashableConformance() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Baaz: Hashable {
            let foo: Foo

            1️⃣static func ==(_ lhs: Baaz, _ rhs: Baaz) -> Bool {
                return lhs.foo == rhs.foo
            }
        }
        """,
      expected: """
        struct Baaz: Hashable {
            let foo: Foo
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove hand-written '==' operator; compiler-synthesized Equatable conformance is equivalent")
      ])
  }

  @Test func removeEquatableWithDidSetProperty() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let bar: Bar

            var baaz: Baaz {
                didSet {
                    print("Updated baaz")
                }
            }

            1️⃣static func ==(lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar && lhs.baaz == rhs.baaz
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let bar: Bar

            var baaz: Baaz {
                didSet {
                    print("Updated baaz")
                }
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove hand-written '==' operator; compiler-synthesized Equatable conformance is equivalent")
      ])
  }

  @Test func removeEquatableWithExplicitReturn() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let x: Int

            1️⃣static func ==(lhs: Foo, rhs: Foo) -> Bool {
                return lhs.x == rhs.x
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let x: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove hand-written '==' operator; compiler-synthesized Equatable conformance is equivalent")
      ])
  }

  // MARK: - No-ops

  @Test func noEquatableConformanceNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo {
            let x: Int
            static func == (lhs: Foo, rhs: Foo) -> Bool {
                lhs.x == rhs.x
            }
        }
        """,
      expected: """
        struct Foo {
            let x: Int
            static func == (lhs: Foo, rhs: Foo) -> Bool {
                lhs.x == rhs.x
            }
        }
        """)
  }

  @Test func notComparingAllPropertiesNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func == (_ lhs: Foo, _ rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let bar: Bar
            let baaz: Baaz

            static func == (_ lhs: Foo, _ rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """)
  }

  @Test func classNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        class Foo: Equatable {
            let bar: Bar

            static func == (_ lhs: Foo, _ rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """,
      expected: """
        class Foo: Equatable {
            let bar: Bar

            static func == (_ lhs: Foo, _ rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """)
  }

  @Test func multiStatementBodyNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let x: Int

            static func == (lhs: Foo, rhs: Foo) -> Bool {
                guard lhs.x == rhs.x else { return false }
                return true
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let x: Int

            static func == (lhs: Foo, rhs: Foo) -> Bool {
                guard lhs.x == rhs.x else { return false }
                return true
            }
        }
        """)
  }

  @Test func noEqualsFuncNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let x: Int
        }
        """,
      expected: """
        struct Foo: Equatable {
            let x: Int
        }
        """)
  }

  @Test func withUsableFromInlineAttributeNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        public struct Foo: Equatable {
            let bar: String

            @usableFromInline
            static func == (lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """,
      expected: """
        public struct Foo: Equatable {
            let bar: String

            @usableFromInline
            static func == (lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """)
  }

  @Test func computedPropertySkipped() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let bar: Bar

            var quux: Quux {
                Quux(bar)
            }

            1️⃣static func ==(lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let bar: Bar

            var quux: Quux {
                Quux(bar)
            }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove hand-written '==' operator; compiler-synthesized Equatable conformance is equivalent")
      ])
  }

  @Test func staticPropertySkipped() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            static let shared: Foo = .init()
            let bar: Bar

            1️⃣static func ==(lhs: Foo, rhs: Foo) -> Bool {
                lhs.bar == rhs.bar
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            static let shared: Foo = .init()
            let bar: Bar
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove hand-written '==' operator; compiler-synthesized Equatable conformance is equivalent")
      ])
  }

  // MARK: - Non-Equatable property types (upstream SwiftFormat #2503)

  /// `Any.Type` defines `==` but is not `Equatable` — synthesized conformance would not compile.
  @Test func anyTypePropertyNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let ty: Any.Type

            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.ty == rhs.ty
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let ty: Any.Type

            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.ty == rhs.ty
            }
        }
        """)
  }

  /// `AnyClass` defines `==` but is not `Equatable` .
  @Test func anyClassPropertyNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let cls: AnyClass

            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.cls == rhs.cls
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let cls: AnyClass

            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.cls == rhs.cls
            }
        }
        """)
  }

  /// Tuples define `==` but do not conform to `Equatable` .
  @Test func tuplePropertyNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let pair: (Int, Int)

            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.pair == rhs.pair
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let pair: (Int, Int)

            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.pair == rhs.pair
            }
        }
        """)
  }

  /// `T.Type` metatypes do not conform to `Equatable` .
  @Test func metatypePropertyNotFlagged() {
    assertFormatting(
      RedundantEquatable.self,
      input: """
        struct Foo: Equatable {
            let ty: Int.Type

            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.ty == rhs.ty
            }
        }
        """,
      expected: """
        struct Foo: Equatable {
            let ty: Int.Type

            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.ty == rhs.ty
            }
        }
        """)
  }
}
