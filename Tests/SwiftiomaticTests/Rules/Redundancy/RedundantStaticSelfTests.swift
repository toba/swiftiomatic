import Testing

@testable import Swiftiomatic

@Suite struct RedundantStaticSelfTests {
  @Test func redundantStaticSelfInStaticVar() {
    let input = """
      enum E { static var x: Int { Self.y } }
      """
    let output = """
      enum E { static var x: Int { y } }
      """
    testFormatting(
      for: input, output, rule: .redundantStaticSelf,
      exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
    )
  }

  @Test func redundantStaticSelfInStaticMethod() {
    let input = """
      enum E { static func foo() { Self.bar() } }
      """
    let output = """
      enum E { static func foo() { bar() } }
      """
    testFormatting(
      for: input, output, rule: .redundantStaticSelf,
      exclude: [.wrapFunctionBodies, .wrapPropertyBodies],
    )
  }

  @Test func redundantStaticSelfOnNextLine() {
    let input = """
      enum E {
          static func foo() {
              Self
                  .bar()
          }
      }
      """
    let output = """
      enum E {
          static func foo() {
              bar()
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantStaticSelf)
  }

  @Test func redundantStaticSelfWithReturn() {
    let input = """
      enum E { static func foo() { return Self.bar() } }
      """
    let output = """
      enum E { static func foo() { return bar() } }
      """
    testFormatting(
      for: input,
      output,
      rule: .redundantStaticSelf,
      exclude: [.wrapFunctionBodies],
    )
  }

  @Test func redundantStaticSelfInConditional() {
    let input = """
      enum E {
          static func foo() {
              if Bool.random() {
                  Self.bar()
              }
          }
      }
      """
    let output = """
      enum E {
          static func foo() {
              if Bool.random() {
                  bar()
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantStaticSelf)
  }

  @Test func redundantStaticSelfInNestedFunction() {
    let input = """
      enum E {
          static func foo() {
              func bar() {
                  Self.foo()
              }
          }
      }
      """
    let output = """
      enum E {
          static func foo() {
              func bar() {
                  foo()
              }
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantStaticSelf)
  }

  @Test func redundantStaticSelfInNestedType() {
    let input = """
      enum Outer {
          enum Inner {
              static func foo() {}
              static func bar() { Self.foo() }
          }
      }
      """
    let output = """
      enum Outer {
          enum Inner {
              static func foo() {}
              static func bar() { foo() }
          }
      }
      """
    testFormatting(
      for: input,
      output,
      rule: .redundantStaticSelf,
      exclude: [.wrapFunctionBodies],
    )
  }

  @Test func staticSelfNotRemovedWhenUsedAsImplicitInitializer() {
    let input = """
      enum E { static func foo() { Self().bar() } }
      """
    testFormatting(for: input, rule: .redundantStaticSelf, exclude: [.wrapFunctionBodies])
  }

  @Test func staticSelfNotRemovedWhenUsedAsExplicitInitializer() {
    let input = """
      enum E { static func foo() { Self.init().bar() } }
      """
    testFormatting(
      for: input, rule: .redundantStaticSelf, exclude: [.wrapFunctionBodies],
    )
  }

  @Test func preservesStaticSelfInFunctionAfterStaticVar() {
    let input = """
      enum MyFeatureCacheStrategy {
          case networkOnly
          case cacheFirst

          static let defaultCacheAge = TimeInterval.minutes(5)

          func requestStrategy<Outcome>() -> SingleRequestStrategy<Outcome> {
              switch self {
              case .networkOnly:
                  return .networkOnly(writeResultToCache: true)
              case .cacheFirst:
                  return .cacheFirst(maxCacheAge: Self.defaultCacheAge)
              }
          }
      }
      """
    testFormatting(for: input, rule: .redundantStaticSelf, exclude: [.propertyTypes])
  }

  @Test func preserveStaticSelfInInstanceFunction() {
    let input = """
      enum Foo {
          static var value = 0

          func f() {
              Self.value = value
          }
      }
      """
    testFormatting(for: input, rule: .redundantStaticSelf)
  }

  @Test func preserveStaticSelfForShadowedProperty() {
    let input = """
      enum Foo {
          static var value = 0

          static func f(value: Int) {
              Self.value = value
          }
      }
      """
    testFormatting(for: input, rule: .redundantStaticSelf)
  }

  @Test func preserveStaticSelfInGetter() {
    let input = """
      enum Foo {
          static let foo: String = "foo"

          var sharedFoo: String {
              Self.foo
          }
      }
      """
    testFormatting(for: input, rule: .redundantStaticSelf)
  }

  @Test func removeStaticSelfInStaticGetter() {
    let input = """
      public enum Foo {
          static let foo: String = "foo"

          static var getFoo: String {
              Self.foo
          }
      }
      """
    let output = """
      public enum Foo {
          static let foo: String = "foo"

          static var getFoo: String {
              foo
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantStaticSelf)
  }

  @Test func preserveStaticSelfInGuardLet() {
    let input = """
      class LocationDeeplink: Deeplink {
          convenience init?(warnRegion: String) {
              guard let value = Self.location(for: warnRegion) else {
                  return nil
              }

              self.init(location: value)
          }
      }
      """
    testFormatting(for: input, rule: .redundantStaticSelf)
  }

  @Test func preserveStaticSelfInSingleLineClassInit() {
    let input = """
      class A { static let defaultName = "A"; let name: String; init() { name = Self.defaultName }}
      """
    testFormatting(for: input, rule: .redundantStaticSelf, exclude: [.wrapFunctionBodies])
  }
}
