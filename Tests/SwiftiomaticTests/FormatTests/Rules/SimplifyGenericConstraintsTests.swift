import Testing

@testable import Swiftiomatic

@Suite struct SimplifyGenericConstraintsTests {
  @Test func simplifyStructGenericConstraint() {
    let input = """
      struct Foo<T> where T: Hashable {}
      """
    let output = """
      struct Foo<T: Hashable> {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func simplifyClassGenericConstraint() {
    let input = """
      class Bar<Element> where Element: Equatable {
          // ...
      }
      """
    let output = """
      class Bar<Element: Equatable> {
          // ...
      }
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func simplifyEnumGenericConstraint() {
    let input = """
      enum Result<Value, Error> where Value: Decodable, Error: Swift.Error {}
      """
    let output = """
      enum Result<Value: Decodable, Error: Swift.Error> {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func simplifyActorGenericConstraint() {
    let input = """
      actor Worker<T> where T: Sendable {}
      """
    let output = """
      actor Worker<T: Sendable> {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func simplifyMultipleConstraintsOnSameType() {
    let input = """
      struct Foo<T> where T: Hashable, T: Codable {}
      """
    let output = """
      struct Foo<T: Hashable & Codable> {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func simplifyMultipleGenericParameters() {
    let input = """
      struct Foo<T, U> where T: Hashable, U: Codable {}
      """
    let output = """
      struct Foo<T: Hashable, U: Codable> {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func preserveExistingInlineConstraints() {
    let input = """
      struct Foo<T: Equatable, U> where U: Codable {}
      """
    let output = """
      struct Foo<T: Equatable, U: Codable> {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func preserveConcreteTypeConstraints() {
    let input = """
      struct Foo<T> where T.Element == String {}
      """
    testFormatting(for: input, rule: .simplifyGenericConstraints)
  }

  @Test func preserveMixedConstraints() {
    let input = """
      struct Foo<T> where T: Collection, T.Element == Int {}
      """
    let output = """
      struct Foo<T: Collection> where T.Element == Int {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func doesntAffectStructsWithoutWhereClause() {
    let input = """
      struct Foo<T: Hashable> {}
      """
    testFormatting(for: input, rule: .simplifyGenericConstraints)
  }

  @Test func doesntAffectStructsWithoutGenerics() {
    let input = """
      struct Foo {}
      """
    testFormatting(for: input, rule: .simplifyGenericConstraints)
  }

  @Test func doesntAffectWhereClauseWithOnlyConcreteTypes() {
    let input = """
      struct Foo<T, U> where T == U {}
      """
    testFormatting(for: input, rule: .simplifyGenericConstraints)
  }

  @Test func realWorldExample() {
    let input = """
      public struct URLImage<Content, Placeholder> where Content: View, Placeholder: View {
          let url: URL
          let content: (Image) -> Content
          let placeholder: () -> Placeholder
      }
      """
    let output = """
      public struct URLImage<Content: View, Placeholder: View> {
          let url: URL
          let content: (Image) -> Content
          let placeholder: () -> Placeholder
      }
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func multilineWhereClause() {
    let input = """
      struct Foo<T, U>
          where T: Hashable,
                U: Codable
      {
          // ...
      }
      """
    let output = """
      struct Foo<T: Hashable, U: Codable>
          {
          // ...
      }
      """
    testFormatting(
      for: input, output, rule: .simplifyGenericConstraints, exclude: [.braces, .indent])
  }

  @Test func simplifyFunctionGenericConstraint() {
    let input = """
      func process<T>(_ value: T) where T: Codable {}
      """
    let output = """
      func process<T: Codable>(_ value: T) {}
      """
    testFormatting(
      for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
  }

  @Test func simplifyFunctionWithMultipleGenericParameters() {
    let input = """
      func compare<T, U>(_ lhs: T, _ rhs: U) where T: Equatable, U: Comparable {}
      """
    let output = """
      func compare<T: Equatable, U: Comparable>(_ lhs: T, _ rhs: U) {}
      """
    testFormatting(
      for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
  }

  @Test func simplifyFunctionWithMultipleConstraintsOnSameType() {
    let input = """
      func handle<T>(_ value: T) where T: Codable, T: Hashable {}
      """
    let output = """
      func handle<T: Codable & Hashable>(_ value: T) {}
      """
    testFormatting(
      for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
  }

  @Test func preserveFunctionWithMixedConstraints() {
    let input = """
      func process<T>(_ value: T) where T: Collection, T.Element == String {}
      """
    let output = """
      func process<T: Collection>(_ value: T) where T.Element == String {}
      """
    testFormatting(
      for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
  }

  // MARK: - Interaction with opaqueGenericParameters

  @Test func worksWithOpaqueGenericParametersToFullySimplify() {
    let input = """
      func foo<T>(_ value: T) where T: Fooable {}
      """
    let output = """
      func foo(_ value: some Fooable) {}
      """
    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(
      for: input, [output], rules: [.simplifyGenericConstraints, .opaqueGenericParameters],
      options: options, exclude: [.unusedArguments])
  }

  @Test func worksWithOpaqueGenericParametersFullConversion() {
    let input = """
      func foo<T, U>(_ t: T, _ u: U) where T: Fooable, U: Barable {}
      """
    let output = """
      func foo(_ t: some Fooable, _ u: some Barable) {}
      """
    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(
      for: input, [output], rules: [.simplifyGenericConstraints, .opaqueGenericParameters],
      options: options, exclude: [.unusedArguments])
  }

  @Test func simplificationOnlyWhenOpaqueCannotApply() {
    let input = """
      func foo<T>(_ value: T) -> T where T: Fooable {}
      """
    let output = """
      func foo<T: Fooable>(_ value: T) -> T {}
      """
    let options = FormatOptions(swiftVersion: "5.7")
    testFormatting(
      for: input, [output], rules: [.simplifyGenericConstraints, .opaqueGenericParameters],
      options: options, exclude: [.unusedArguments])
  }

  @Test func partialSimplification() {
    let input = """
      struct Foo<T, U> where T: Hashable, U.Element == String {}
      """
    let output = """
      struct Foo<T: Hashable, U> where U.Element == String {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  // MARK: - Complex cases with many generics

  @Test func structWithFourGenerics() {
    let input = """
      struct Foo<A, B, C, D> where A: Hashable, B: Codable, C: Equatable, D: Comparable {}
      """
    let output = """
      struct Foo<A: Hashable, B: Codable, C: Equatable, D: Comparable> {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func structWithSixGenerics() {
    let input = """
      struct Complex<A, B, C, D, E, F>
          where A: Hashable,
                B: Codable,
                C: Equatable,
                D: Comparable,
                E: Collection,
                F: Sequence
      {
          var values: (A, B, C, D, E, F)
      }
      """
    let output = """
      struct Complex<A: Hashable, B: Codable, C: Equatable, D: Comparable, E: Collection, F: Sequence>
          {
          var values: (A, B, C, D, E, F)
      }
      """
    testFormatting(
      for: input, output, rule: .simplifyGenericConstraints, exclude: [.braces, .indent])
  }

  @Test func functionWithFiveGenerics() {
    let input = """
      func process<A, B, C, D, E>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E)
          where A: Codable, B: Hashable, C: Equatable, D: Comparable, E: Collection
      {}
      """
    let output = """
      func process<A: Codable, B: Hashable, C: Equatable, D: Comparable, E: Collection>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E)
          {}
      """
    testFormatting(
      for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments, .indent])
  }

  @Test func manyGenericsWithMixedConstraints() {
    let input = """
      struct Foo<A, B, C, D, E> where A: Hashable, B: Collection, B.Element == String, C: Codable, D.Index == Int, E: Equatable {
          var values: (A, B, C, D, E)
      }
      """
    let output = """
      struct Foo<A: Hashable, B: Collection, C: Codable, D, E: Equatable> where B.Element == String, D.Index == Int {
          var values: (A, B, C, D, E)
      }
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func manyGenericsWithMultipleConstraintsPerType() {
    let input = """
      func transform<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D)
          where A: Hashable,
                A: Codable,
                B: Collection,
                B: Equatable,
                C: Comparable,
                D: Sequence,
                D: Sendable
      {}
      """
    let output = """
      func transform<A: Hashable & Codable, B: Collection & Equatable, C: Comparable, D: Sequence & Sendable>(_ a: A, _ b: B, _ c: C, _ d: D)
          {}
      """
    testFormatting(
      for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments, .indent])
  }

  @Test func doesNotSimplifyWhenCombinedCompositionIsTooLong() {
    // When multiple constraints for the same type are combined with &,
    // don't simplify if the result is over 40 characters
    let input = """
      func transform<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D)
          where A: VeryLongProtocolName,
                A: AnotherVeryLongProtocolName,
                B: Collection,
                C: Comparable,
                D: Sequence
      {}
      """
    testFormatting(
      for: input, rule: .simplifyGenericConstraints, exclude: [.unusedArguments, .indent])
  }

  // MARK: - Constraints on generics not in parameter list

  @Test func preserveConstraintsForGenericsNotInParameterList() {
    // U is not in the function's generic parameters, so the constraint must be preserved
    let input = """
      func process<T>(value: T) where U: Hashable {
          print(U.self)
      }
      """
    testFormatting(for: input, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
  }

  @Test func combineInlineAndWhereClauseConstraints() {
    // When a generic has both inline and where clause constraints, combine with &
    let input = """
      struct Config<T: Hashable> where T: Codable {}
      """
    let output = """
      struct Config<T: Hashable & Codable> {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func combineMultipleInlineAndWhereClauseConstraints() {
    // Multiple constraints should all be combined with &
    let input = """
      struct Config<T: Hashable, U: Codable> where T: Sendable, U: Equatable {}
      """
    let output = """
      struct Config<T: Hashable & Sendable, U: Codable & Equatable> {}
      """
    testFormatting(for: input, output, rule: .simplifyGenericConstraints)
  }

  @Test func multilineWhereClauseWithLineBreaksAfterAmpersand() {
    // Don't simplify multiline where clauses with line breaks after & - too error prone
    let input = """
      enum Section<Context>: Component
        where Context: ProviderA & ProviderB &
        ProviderC &
        ProviderD
      {}
      """
    testFormatting(for: input, rule: .simplifyGenericConstraints, exclude: [.indent])
  }

  @Test func protocolMethodWithWhereClause() {
    let input = """
      protocol Foo {
          func bar<T>(_ value: T) async throws -> T where T: Codable
      }
      """
    let output = """
      protocol Foo {
          func bar<T: Codable>(_ value: T) async throws -> T
      }
      """
    testFormatting(
      for: input, output, rule: .simplifyGenericConstraints, exclude: [.unusedArguments])
  }

  @Test func multilineConstraintWithQualifiedTypeName() {
    // Don't simplify when protocol composition spans multiple lines with & operators
    let input = """
      enum Foo<T>: SomeProtocol where
        T: ModuleName.ProtocolA & ProtocolB & ProtocolC
        & ProtocolD & ProtocolE
        & ProtocolF
      {
      }
      """
    testFormatting(for: input, rule: .simplifyGenericConstraints, exclude: [.indent, .emptyBraces])
  }

  @Test func doesNotSimplifyLongProtocolComposition() {
    // Don't simplify when protocol composition is over 40 characters
    // This prevents awkward line breaks when wrapArguments is applied
    let input = """
      enum Foo<T>: SomeProtocol where
        T: ProtocolA & SomeModule.ProtocolB & ProtocolC
      {
      }
      """
    testFormatting(for: input, rule: .simplifyGenericConstraints, exclude: [.indent, .emptyBraces])
  }

  @Test func doesNotSimplifySingleLongProtocolName() {
    // Don't simplify when a single protocol name is over 40 characters
    let input = """
      enum Foo<T>: SomeProtocol where T: VeryLongProtocolNameThatIsOverFortyCharacters
      {
      }
      """
    testFormatting(
      for: input, rule: .simplifyGenericConstraints, exclude: [.indent, .emptyBraces, .braces])
  }
}
