import Testing

@testable import Swiftiomatic

@Suite struct RedundantPublicTests {
  @Test func removesPublicFromPropertyInInternalStruct() {
    let input = """
      struct Foo {
          public let bar: Bar
      }
      """
    let output = """
      struct Foo {
          let bar: Bar
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic])
  }

  @Test func removesPublicFromMethodInInternalClass() {
    let input = """
      class Example {
          public func doSomething() {}
      }
      """
    let output = """
      class Example {
          func doSomething() {}
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic])
  }

  @Test func doesNotRemovePublicFromMethodInInternalClassWithSPI() {
    let input = """
      class Example {
          @_spi(Example)
          public func doSomething() {}
      }
      """
    testFormatting(for: input, rules: [.redundantPublic])
  }

  @Test func removesPublicFromMultipleDeclarationsInInternalType() {
    let input = """
      struct Container {
          public let value: Int
          public var name: String
          public func calculate() -> Int { 42 }
          public init(value: Int, name: String) {
              self.value = value
              self.name = name
          }
      }
      """
    let output = """
      struct Container {
          let value: Int
          var name: String
          func calculate() -> Int { 42 }
          init(value: Int, name: String) {
              self.value = value
              self.name = name
          }
      }
      """
    testFormatting(
      for: input, [output], rules: [.redundantPublic],
      exclude: [.redundantMemberwiseInit, .wrapFunctionBodies],
    )
  }

  @Test func doesNotRemovePublicFromPublicType() {
    let input = """
      public struct PublicStruct {
          public let value: String
          public func getValue() -> String { value }
      }
      """
    testFormatting(for: input, rules: [.redundantPublic], exclude: [.wrapFunctionBodies])
  }

  @Test func removesPublicFromExplicitlyInternalType() {
    let input = """
      internal struct InternalStruct {
          public var count: Int
          public func increment() { count += 1 }
      }
      """
    let output = """
      internal struct InternalStruct {
          var count: Int
          func increment() { count += 1 }
      }
      """
    testFormatting(
      for: input, [output], rules: [.redundantPublic],
      exclude: [.redundantInternal, .wrapFunctionBodies],
    )
  }

  @Test func removesPublicFromPrivateType() {
    let input = """
      private struct PrivateStruct {
          public let value: String
      }
      """
    let output = """
      private struct PrivateStruct {
          let value: String
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic])
  }

  @Test func removesPublicFromFileprivateType() {
    let input = """
      fileprivate class Helper {
          public func help() {}
      }
      """
    let output = """
      fileprivate class Helper {
          func help() {}
      }
      """
    testFormatting(
      for: input, [output], rules: [.redundantPublic], exclude: [.redundantFileprivate],
    )
  }

  @Test func removesPublicFromNestedTypeInInternalParent() {
    let input = """
      struct Outer {
          struct Inner {
              public var value: Int
          }
      }
      """
    let output = """
      struct Outer {
          struct Inner {
              var value: Int
          }
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic], exclude: [.enumNamespaces])
  }

  @Test func preservesPublicInExtension() {
    let input = """
      extension Array {
          public var isNotEmpty: Bool { !isEmpty }
      }
      """
    testFormatting(
      for: input, rules: [.redundantPublic],
      exclude: [
        .wrapFunctionBodies,
        .wrapPropertyBodies,
      ],
    )
  }

  @Test func preservesPublicInTypeInPublicExtension() {
    let input = """
      public extension Foo {
          struct Bar {
              public var baaz: Baaz
          }
      }
      """
    testFormatting(for: input, rules: [.redundantPublic])
  }

  @Test func removesPublicInExtensionOfInternalTypeInSameFile() {
    let input = """
      struct InternalType {}

      extension InternalType {
          public func foo() {}
          public func bar() {}

          #if DEBUG
              public func baaz() {}
          #endif
      }
      """

    let output = """
      struct InternalType {}

      extension InternalType {
          func foo() {}
          func bar() {}

          #if DEBUG
              func baaz() {}
          #endif
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic])
  }

  @Test func removesPublicInExtensionOfNestedInternalType() {
    let input = """
      enum OuterType {
          public struct InnerType {
              let num: Int
          }
      }

      extension OuterType.InnerType {
          public func calculate() -> Int { num * 2 }
      }
      """

    let output = """
      enum OuterType {
          struct InnerType {
              let num: Int
          }
      }

      extension OuterType.InnerType {
          func calculate() -> Int { num * 2 }
      }
      """
    testFormatting(
      for: input,
      [output],
      rules: [.redundantPublic],
      exclude: [.wrapFunctionBodies],
    )
  }

  @Test func removesPublicInTypeInExtension() {
    let input = """
      extension Foo {
          struct Bar {
              public var baaz: Int
          }
      }
      """

    let output = """
      extension Foo {
          struct Bar {
              var baaz: Int
          }
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic])
  }

  @Test func removesPublicFromEnumCasesInInternalEnum() {
    let input = """
      enum State {
          public static let initialValue = 0
          case idle
          case loading
      }
      """
    let output = """
      enum State {
          static let initialValue = 0
          case idle
          case loading
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic])
  }

  @Test func handlesConditionalCompilation() {
    let input = """
      struct Container {
          #if DEBUG
          public let debugValue: String
          #else
          public let releaseValue: String
          #endif
      }
      """
    let output = """
      struct Container {
          #if DEBUG
          let debugValue: String
          #else
          let releaseValue: String
          #endif
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic], exclude: [.indent])
  }

  @Test func preservesInternalModifierWhenRemovingPublic() {
    let input = """
      struct Foo {
          public internal(set) var value: Int
      }
      """
    let output = """
      struct Foo {
          internal(set) var value: Int
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic])
  }

  @Test func preservesPublicInConditionalCompilationInsideExtension() {
    let input = """
      extension Foo {
          #if DEBUG
              public var publicProperty: Int { 10 }

          #if OTHER_CONDITION
              public var otherPublicProperty: Int { 10 }
          #endif
          #endif
      }
      """
    testFormatting(
      for: input, rules: [.redundantPublic],
      exclude: [.indent, .wrapFunctionBodies, .wrapPropertyBodies],
    )
  }

  @Test func preservesPublicInNestedTypeInsidePublicExtension() {
    let input = """
      public extension Foo {
          struct Bar {
              private var foo: Int
              private let bar: Int

              public var foobar: (Int, Int) {
                  (foo, bar)
              }

              public init(foo: Int, bar: Int) {
                  self.foo = foo
                  self.bar = bar
              }
          }
      }
      """
    testFormatting(for: input, rules: [.redundantPublic])
  }

  @Test func preservesPublicInProtocolExtension() {
    // A method in an extension of an internal protocol may actually be publicly accessible
    // via some public type that implements the protocol.
    let input = """
      protocol Foo {}

      extension Foo {
          public func bar() {}
      }
      """
    testFormatting(for: input, rules: [.redundantPublic])
  }

  @Test func treatsTypeInPublicExtensionAsPublic() {
    let input = """
      public enum Foo {}

      public extension Foo {
          enum Bar {}
      }

      extension Foo {
          enum Baaz {}
      }

      extension Foo.Bar: CustomStringConvertible {
          public var description: String {
              ""
          }
      }

      extension Foo.Baaz: CustomStringConvertible {
          public var description: String {
              ""
          }
      }
      """

    let output = """
      public enum Foo {}

      public extension Foo {
          enum Bar {}
      }

      extension Foo {
          enum Baaz {}
      }

      extension Foo.Bar: CustomStringConvertible {
          public var description: String {
              ""
          }
      }

      extension Foo.Baaz: CustomStringConvertible {
          var description: String {
              ""
          }
      }
      """
    testFormatting(for: input, output, rule: .redundantPublic)
  }

  @Test func removesPublicFromComplexPrivateStruct() {
    let input = """
      private struct Example {
          public var value: Int
          public func test() {}
      }
      """
    let output = """
      private struct Example {
          var value: Int
          func test() {}
      }
      """
    testFormatting(for: input, [output], rules: [.redundantPublic])
  }
}
