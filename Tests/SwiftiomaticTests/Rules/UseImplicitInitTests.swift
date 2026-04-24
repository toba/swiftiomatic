@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseImplicitInitTests: RuleTesting {

  // MARK: - Computed properties

  @Test func computedPropertyWithExplicitInit() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          static var defaultValue: Bar { 1️⃣Bar(x: 1) }
        }
        """,
      expected: """
        struct Foo {
          static var defaultValue: Bar { .init(x: 1) }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Bar(x: 1)' with '.init(x: 1)'"),
      ]
    )
  }

  @Test func computedPropertyAlreadyImplicit() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          static var defaultValue: Bar { .init(x: 1) }
        }
        """,
      expected: """
        struct Foo {
          static var defaultValue: Bar { .init(x: 1) }
        }
        """,
      findings: []
    )
  }

  @Test func computedPropertyWithDifferentType() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          var value: Bar { Baz(x: 1) }
        }
        """,
      expected: """
        struct Foo {
          var value: Bar { Baz(x: 1) }
        }
        """,
      findings: []
    )
  }

  @Test func computedPropertyWithMultipleStatements() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          var value: Bar {
            let x = 1
            return 1️⃣Bar(x: x)
          }
        }
        """,
      expected: """
        struct Foo {
          var value: Bar {
            let x = 1
            return .init(x: x)
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Bar(x: x)' with '.init(x: x)'"),
      ]
    )
  }

  // MARK: - Function return types

  @Test func functionReturnWithExplicitType() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        func make() -> Config {
          return 1️⃣Config(debug: true)
        }
        """,
      expected: """
        func make() -> Config {
          return .init(debug: true)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Config(debug: true)' with '.init(debug: true)'"),
      ]
    )
  }

  @Test func functionSingleExpressionBody() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        func make() -> Config { 1️⃣Config(debug: true) }
        """,
      expected: """
        func make() -> Config { .init(debug: true) }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Config(debug: true)' with '.init(debug: true)'"),
      ]
    )
  }

  // MARK: - Default parameter values

  @Test func defaultParameterValue() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        func run(mode: Mode = 1️⃣Mode(fast: true)) {}
        """,
      expected: """
        func run(mode: Mode = .init(fast: true)) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Mode(fast: true)' with '.init(fast: true)'"),
      ]
    )
  }

  @Test func defaultParameterValueDifferentType() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        func run(mode: Mode = Other(fast: true)) {}
        """,
      expected: """
        func run(mode: Mode = Other(fast: true)) {}
        """,
      findings: []
    )
  }

  // MARK: - Stored properties with type annotation (single-expression initializer)

  @Test func storedPropertyWithTypeAnnotation() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        let config: Config = 1️⃣Config(debug: true)
        """,
      expected: """
        let config: Config = .init(debug: true)
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Config(debug: true)' with '.init(debug: true)'"),
      ]
    )
  }

  // MARK: - Static member access

  @Test func staticMemberAccessOnComputedProperty() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          var color: Color { 1️⃣Color.red }
        }
        """,
      expected: """
        struct Foo {
          var color: Color { .red }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Color.red' with '.red'"),
      ]
    )
  }

  @Test func staticMemberAccessDifferentType() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          var color: Color { Other.red }
        }
        """,
      expected: """
        struct Foo {
          var color: Color { Other.red }
        }
        """,
      findings: []
    )
  }

  @Test func staticMemberAccessInDefaultParam() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        func draw(color: Color = 1️⃣Color.red) {}
        """,
      expected: """
        func draw(color: Color = .red) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Color.red' with '.red'"),
      ]
    )
  }

  // MARK: - No-argument constructors

  @Test func noArgConstructor() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          static var value: Bar { 1️⃣Bar() }
        }
        """,
      expected: """
        struct Foo {
          static var value: Bar { .init() }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Bar()' with '.init()'"),
      ]
    )
  }

  // MARK: - Should not fire

  @Test func noReturnType() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        func make() {
          let x = Config(debug: true)
        }
        """,
      expected: """
        func make() {
          let x = Config(debug: true)
        }
        """,
      findings: []
    )
  }

  @Test func alreadyDotInit() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        func make() -> Config { .init(debug: true) }
        """,
      expected: """
        func make() -> Config { .init(debug: true) }
        """,
      findings: []
    )
  }

  @Test func genericReturnType() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          var items: Array<Int> { 1️⃣Array<Int>() }
        }
        """,
      expected: """
        struct Foo {
          var items: Array<Int> { .init() }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Array<Int>()' with '.init()'"),
      ]
    )
  }

  @Test func chainedCallNotChanged() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          var value: String { String(data).uppercased() }
        }
        """,
      expected: """
        struct Foo {
          var value: String { String(data).uppercased() }
        }
        """,
      findings: []
    )
  }

  @Test func staticFactoryCallWithArgs() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        func make() -> Config {
          return 1️⃣Config.make(debug: true)
        }
        """,
      expected: """
        func make() -> Config {
          return .make(debug: true)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Config.make(debug: true)' with '.make(debug: true)'"),
      ]
    )
  }

  // MARK: - Subscript return types

  @Test func subscriptReturnType() {
    assertFormatting(
      UseImplicitInit.self,
      input: """
        struct Foo {
          subscript(index: Int) -> Bar { 1️⃣Bar(index: index) }
        }
        """,
      expected: """
        struct Foo {
          subscript(index: Int) -> Bar { .init(index: index) }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace 'Bar(index: index)' with '.init(index: index)'"),
      ]
    )
  }
}
