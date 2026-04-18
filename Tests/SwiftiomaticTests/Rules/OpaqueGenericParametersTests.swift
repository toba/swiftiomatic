@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct OpaqueGenericParametersTests: RuleTesting {

  @Test func basicNoConstraint() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣func foo<T>(_ value: T) {
            print(value)
        }
        """,
      expected: """
        func foo(_ value: some Any) {
            print(value)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func constraintInBracket() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣func foo<T: Fooable, U: Barable>(_ fooable: T, barable: U) -> Baaz {
            print(fooable, barable)
        }
        """,
      expected: """
        func foo(_ fooable: some Fooable, barable: some Barable) -> Baaz {
            print(fooable, barable)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func constraintsInWhereClause() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣func foo<T, U>(_ t: T, _ u: U) -> Baaz where T: Fooable, T: Barable, U: Baazable {
            print(t, u)
        }
        """,
      expected: """
        func foo(_ t: some Fooable & Barable, _ u: some Baazable) -> Baaz {
            print(t, u)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func initDeclaration() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣init<T: Fooable, U: Barable>(_ fooable: T, barable: U) {
            print(fooable, barable)
        }
        """,
      expected: """
        init(_ fooable: some Fooable, barable: some Barable) {
            print(fooable, barable)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func subscriptDeclaration() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣subscript<T: Fooable, U: Barable>(_ fooable: T, barable: U) -> Any {
            (fooable, barable)
        }
        """,
      expected: """
        subscript(_ fooable: some Fooable, barable: some Barable) -> Any {
            (fooable, barable)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func typeUsedMultipleTimesNotChanged() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func foo<T: Fooable>(_ first: T, second: T) {
            print(first, second)
        }
        """,
      expected: """
        func foo<T: Fooable>(_ first: T, second: T) {
            print(first, second)
        }
        """,
      findings: []
    )
  }

  @Test func typeUsedAsReturnNotChanged() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func foo<T: Fooable>() -> T {
            fatalError()
        }
        """,
      expected: """
        func foo<T: Fooable>() -> T {
            fatalError()
        }
        """,
      findings: []
    )
  }

  @Test func typeUsedAsReturnAndParamNotChanged() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func foo<T: Fooable>(_ value: T) -> T {
            value
        }
        """,
      expected: """
        func foo<T: Fooable>(_ value: T) -> T {
            value
        }
        """,
      findings: []
    )
  }

  @Test func typeUsedInBodyNotChanged() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func foo<T>(_ value: T) {
            typealias TTT = T
            let casted = value as TTT
            print(casted)
        }
        """,
      expected: """
        func foo<T>(_ value: T) {
            typealias TTT = T
            let casted = value as TTT
            print(casted)
        }
        """,
      findings: []
    )
  }

  @Test func sameTypeConstraint() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣func foo<T>(with _: T) -> Foo where T == Dependencies {}
        """,
      expected: """
        func foo(with _: Dependencies) -> Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func variadic() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func variadic<T>(_ t: T...) {
            print(t)
        }
        """,
      expected: """
        func variadic<T>(_ t: T...) {
            print(t)
        }
        """,
      findings: []
    )
  }

  @Test func closureParameterNotChanged() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func foo<Foo>(_: (Foo) -> Void) {}
        """,
      expected: """
        func foo<Foo>(_: (Foo) -> Void) {}
        """,
      findings: []
    )
  }

  @Test func addsParensAroundTypeIfNecessary() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣func foo<Foo>(_: Foo.Type) {}
        """,
      expected: """
        func foo(_: (some Any).Type) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func addsParensAroundOptional() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣func bar<Foo>(_: Foo?) {}
        """,
      expected: """
        func bar(_: (some Any)?) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func canRemoveOneButNotOthers() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣func foo<T: Fooable, U: Barable>(_ foo: T, bar1: U, bar2: U) where T: Quuxable {
            print(foo, bar1, bar2)
        }
        """,
      expected: """
        func foo<U: Barable>(_ foo: some Fooable & Quuxable, bar1: U, bar2: U) {
            print(foo, bar1, bar2)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func genericConstraintThatIsGeneric() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        1️⃣func bar<T: Bar<String>>(_: T) {}
        """,
      expected: """
        func bar(_: some Bar<String>) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func constraintReferencesItself() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func makeSections<ViewModelContext: RoutingBehaviors<ViewModelContext.Dependencies>>(_: ViewModelContext) {}
        """,
      expected: """
        func makeSections<ViewModelContext: RoutingBehaviors<ViewModelContext.Dependencies>>(_: ViewModelContext) {}
        """,
      findings: []
    )
  }

  @Test func genericUsedInOtherConstraint() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func combineResults<ASuccess, AFailure, BSuccess, BFailure>(
            _: Potential<ASuccess, AFailure>,
            _: Potential<BSuccess, BFailure>
        ) -> Potential<Success, Never> where
            Success == (Result<ASuccess, AFailure>, Result<BSuccess, BFailure>),
            Failure == Never
        {}
        """,
      expected: """
        func combineResults<ASuccess, AFailure, BSuccess, BFailure>(
            _: Potential<ASuccess, AFailure>,
            _: Potential<BSuccess, BFailure>
        ) -> Potential<Success, Never> where
            Success == (Result<ASuccess, AFailure>, Result<BSuccess, BFailure>),
            Failure == Never
        {}
        """,
      findings: []
    )
  }

  @Test func genericThrowsType() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func sample<ErrorType>(error: ErrorType) throws(ErrorType) {
            throw error
        }
        """,
      expected: """
        func sample<ErrorType>(error: ErrorType) throws(ErrorType) {
            throw error
        }
        """,
      findings: []
    )
  }

  @Test func attributeReferencesGeneric() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        @_specialize(where S == Int)
        func foo<S: Sequence>(_ t: S) {
            print(t)
        }
        """,
      expected: """
        @_specialize(where S == Int)
        func foo<S: Sequence>(_ t: S) {
            print(t)
        }
        """,
      findings: []
    )
  }

  @Test func genericWithAttributeOrMacro() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        @MyResultBuilder
        1️⃣func foo<T: Foo, U: Bar>(foo: T, bar: U) -> MyResult {
            foo
            bar
        }
        """,
      expected: """
        @MyResultBuilder
        func foo(foo: some Foo, bar: some Bar) -> MyResult {
            foo
            bar
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func nestedFunction() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func test() {
            1️⃣func foo<T: Fooable, U>(_ fooable: T, barable: U) -> Baaz where U: Barable {
                print(fooable, barable)
            }

            print(foo(fooable, barable))
        }
        """,
      expected: """
        func test() {
            func foo(_ fooable: some Fooable, barable: some Barable) -> Baaz {
                print(fooable, barable)
            }

            print(foo(fooable, barable))
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func preservesGenericInAnyExistential() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func foo<T: StringProtocol>(_ collection: any Collection<T>) {
            print(collection)
        }
        """,
      expected: """
        func foo<T: StringProtocol>(_ collection: any Collection<T>) {
            print(collection)
        }
        """,
      findings: []
    )
  }

  @Test func protocolRequirement() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        protocol FooProtocol {
            1️⃣func bar<T: Collection>(_ bars: T)
        }
        """,
      expected: """
        protocol FooProtocol {
            func bar(_ bars: some Collection)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'some' opaque parameter instead of named generic parameter"),
      ]
    )
  }

  @Test func whereClauseWithAssociatedTypeConformance() {
    // T.AssociatedType: Bar is not representable with opaque syntax
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        func foo<T: Fooable>(_ value: T) where T.AssociatedType: Bar {
            print(value)
        }
        """,
      expected: """
        func foo<T: Fooable>(_ value: T) where T.AssociatedType: Bar {
            print(value)
        }
        """,
      findings: []
    )
  }

  @Test func preservesGenericUsedInBodyAtEndOfScope() {
    assertFormatting(
      OpaqueGenericParameters.self,
      input: """
        public static func decodableTransformer<T: Decodable>(for _: T.Type) -> ValueTransformer {
            CodableTransformer<T>.default
        }
        """,
      expected: """
        public static func decodableTransformer<T: Decodable>(for _: T.Type) -> ValueTransformer {
            CodableTransformer<T>.default
        }
        """,
      findings: []
    )
  }
}
