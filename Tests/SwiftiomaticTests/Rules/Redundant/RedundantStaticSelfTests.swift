@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantStaticSelfTests: RuleTesting {

  // MARK: - Adapted from SwiftFormat

  @Test func redundantStaticSelfInStaticVar() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum E {
          static var x: Int { 1️⃣Self.y }
        }
        """,
      expected: """
        enum E {
          static var x: Int { y }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  @Test func redundantStaticSelfInStaticMethod() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum E {
          static func foo() { 1️⃣Self.bar() }
        }
        """,
      expected: """
        enum E {
          static func foo() { bar() }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  @Test func redundantStaticSelfOnNextLine() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum E {
          static func foo() {
            1️⃣Self
              .bar()
          }
        }
        """,
      expected: """
        enum E {
          static func foo() {
            bar()
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  @Test func redundantStaticSelfWithReturn() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum E {
          static func foo() { return 1️⃣Self.bar() }
        }
        """,
      expected: """
        enum E {
          static func foo() { return bar() }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  @Test func redundantStaticSelfInConditional() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum E {
          static func foo() {
            if Bool.random() {
              1️⃣Self.bar()
            }
          }
        }
        """,
      expected: """
        enum E {
          static func foo() {
            if Bool.random() {
              bar()
            }
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  @Test func redundantStaticSelfInNestedFunction() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum E {
          static func foo() {
            func bar() {
              1️⃣Self.foo()
            }
          }
        }
        """,
      expected: """
        enum E {
          static func foo() {
            func bar() {
              foo()
            }
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  @Test func redundantStaticSelfInNestedType() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum Outer {
          enum Inner {
            static func foo() {}
            static func bar() { 1️⃣Self.foo() }
          }
        }
        """,
      expected: """
        enum Outer {
          enum Inner {
            static func foo() {}
            static func bar() { foo() }
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  @Test func removeStaticSelfInStaticGetter() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        public enum Foo {
          static let foo: String = "foo"

          static var getFoo: String {
            1️⃣Self.foo
          }
        }
        """,
      expected: """
        public enum Foo {
          static let foo: String = "foo"

          static var getFoo: String {
            foo
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'Self.' in static context"),
      ]
    )
  }

  // MARK: - Preserve Self (should NOT remove)

  @Test func staticSelfNotRemovedWhenUsedAsImplicitInitializer() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum E {
          static func foo() { Self().bar() }
        }
        """,
      expected: """
        enum E {
          static func foo() { Self().bar() }
        }
        """,
      findings: []
    )
  }

  @Test func staticSelfNotRemovedWhenUsedAsExplicitInitializer() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum E {
          static func foo() { Self.init().bar() }
        }
        """,
      expected: """
        enum E {
          static func foo() { Self.init().bar() }
        }
        """,
      findings: []
    )
  }

  @Test func preservesStaticSelfInFunctionAfterStaticVar() {
    // Instance method accessing static member — Self is required
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum MyFeatureCacheStrategy {
          case networkOnly
          case cacheFirst

          static let defaultCacheAge = 300.0

          func requestStrategy() -> Int {
            switch self {
            case .networkOnly:
              return 1
            case .cacheFirst:
              return Int(Self.defaultCacheAge)
            }
          }
        }
        """,
      expected: """
        enum MyFeatureCacheStrategy {
          case networkOnly
          case cacheFirst

          static let defaultCacheAge = 300.0

          func requestStrategy() -> Int {
            switch self {
            case .networkOnly:
              return 1
            case .cacheFirst:
              return Int(Self.defaultCacheAge)
            }
          }
        }
        """,
      findings: []
    )
  }

  @Test func preserveStaticSelfInInstanceFunction() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum Foo {
          static var value = 0

          func f() {
            Self.value = value
          }
        }
        """,
      expected: """
        enum Foo {
          static var value = 0

          func f() {
            Self.value = value
          }
        }
        """,
      findings: []
    )
  }

  @Test func preserveStaticSelfForShadowedProperty() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum Foo {
          static var value = 0

          static func f(value: Int) {
            Self.value = value
          }
        }
        """,
      expected: """
        enum Foo {
          static var value = 0

          static func f(value: Int) {
            Self.value = value
          }
        }
        """,
      findings: []
    )
  }

  @Test func preserveStaticSelfInGetter() {
    // Instance getter accessing static member — Self is required
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        enum Foo {
          static let foo: String = "foo"

          var sharedFoo: String {
            Self.foo
          }
        }
        """,
      expected: """
        enum Foo {
          static let foo: String = "foo"

          var sharedFoo: String {
            Self.foo
          }
        }
        """,
      findings: []
    )
  }

  @Test func preserveStaticSelfInGuardLet() {
    // convenience init is NOT a static context
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        class LocationDeeplink {
          convenience init?(warnRegion: String) {
            guard let value = Self.location(for: warnRegion) else {
              return nil
            }
            self.init(location: value)
          }
        }
        """,
      expected: """
        class LocationDeeplink {
          convenience init?(warnRegion: String) {
            guard let value = Self.location(for: warnRegion) else {
              return nil
            }
            self.init(location: value)
          }
        }
        """,
      findings: []
    )
  }

  @Test func preserveStaticSelfInSingleLineClassInit() {
    // init is NOT a static context
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        class A {
          static let defaultName = "A"
          let name: String
          init() { name = Self.defaultName }
        }
        """,
      expected: """
        class A {
          static let defaultName = "A"
          let name: String
          init() { name = Self.defaultName }
        }
        """,
      findings: []
    )
  }

  // MARK: - Additional tests

  @Test func topLevelNotFlagged() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        let x = Self.value
        """,
      expected: """
        let x = Self.value
        """,
      findings: []
    )
  }

  @Test func classFuncRemovesSelf() {
    assertFormatting(
      RedundantStaticSelf.self,
      input: """
        class Foo {
          class func bar() {
            print(1️⃣Self.value)
          }
          static let value = 1
        }
        """,
      expected: """
        class Foo {
          class func bar() {
            print(value)
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
