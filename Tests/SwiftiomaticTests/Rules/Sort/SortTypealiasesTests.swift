@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct SortTypealiasesTests: RuleTesting {

  // MARK: - Single line

  @Test func sortSingleLineTypealias() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        1️⃣typealias Placeholders = Foo & Bar & Quux & Baaz
        """,
      expected: """
        typealias Placeholders = Baaz & Bar & Foo & Quux
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort protocol composition types alphabetically"),
      ]
    )
  }

  @Test func alreadySorted() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        typealias Deps = Bar & Baz & Foo
        """,
      expected: """
        typealias Deps = Bar & Baz & Foo
        """,
      findings: []
    )
  }

  // MARK: - Multiline

  @Test func sortWrappedMultilineTypealias() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        1️⃣typealias Dependencies = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """,
      expected: """
        typealias Dependencies = BaazProviding
            & BarProviding
            & FooProviding
            & QuuxProviding
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort protocol composition types alphabetically"),
      ]
    )
  }

  @Test func sortWrappedMultilineTypealiasEqualsOnNewLine() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        1️⃣typealias Dependencies
            = FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """,
      expected: """
        typealias Dependencies
            = BaazProviding
            & BarProviding
            & FooProviding
            & QuuxProviding
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort protocol composition types alphabetically"),
      ]
    )
  }

  // MARK: - Any prefix

  @Test func sortWithAnyPrefix() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        1️⃣typealias Wrapped = any UIView & UIContentView
        """,
      expected: """
        typealias Wrapped = any UIContentView & UIView
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort protocol composition types alphabetically"),
      ]
    )
  }

  @Test func sortWrappedMultilineWithAny() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        1️⃣typealias Dependencies
            = any FooProviding
            & BarProviding
            & BaazProviding
            & QuuxProviding
        """,
      expected: """
        typealias Dependencies
            = any BaazProviding
            & BarProviding
            & FooProviding
            & QuuxProviding
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort protocol composition types alphabetically"),
      ]
    )
  }

  // MARK: - Duplicates

  @Test func removeDuplicates() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        1️⃣typealias Placeholders = Foo & Bar & Quux & Baaz & Bar
        """,
      expected: """
        typealias Placeholders = Baaz & Bar & Foo & Quux
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort protocol composition types alphabetically"),
      ]
    )
  }

  // MARK: - Generic types

  @Test func sortTypealiasesWithGenericTypes() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        1️⃣typealias Collections
            = Collection<Int>
            & Collection<String>
            & Collection<Double>
            & Collection<Float>
        """,
      expected: """
        typealias Collections
            = Collection<Double>
            & Collection<Float>
            & Collection<Int>
            & Collection<String>
        """,
      findings: [
        FindingSpec("1️⃣", message: "sort protocol composition types alphabetically"),
      ]
    )
  }

  // MARK: - Non-composition types (should not sort)

  @Test func arrayOfExistentialNotSorted() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        public typealias Parameters = [any Any & Sendable]
        """,
      expected: """
        public typealias Parameters = [any Any & Sendable]
        """,
      findings: []
    )
  }

  @Test func dictionaryOfExistentialNotSorted() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        public typealias Parameters = [any Hashable & Sendable: any Any & Sendable]
        """,
      expected: """
        public typealias Parameters = [any Hashable & Sendable: any Any & Sendable]
        """,
      findings: []
    )
  }

  @Test func optionalExistentialNotSorted() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        public typealias Parameters = (Hashable & Sendable)?
        """,
      expected: """
        public typealias Parameters = (Hashable & Sendable)?
        """,
      findings: []
    )
  }

  @Test func genericExistentialNotSorted() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        public typealias Parameters = Result<any Hashable & Sendable, any Error & Sendable>
        """,
      expected: """
        public typealias Parameters = Result<any Hashable & Sendable, any Error & Sendable>
        """,
      findings: []
    )
  }

  @Test func closureTypeNotSorted() {
    assertFormatting(
      SortTypealiases.self,
      input: """
        public typealias Parameters = (any Hashable & Sendable, any Error & Sendable) -> any Equatable & Codable
        """,
      expected: """
        public typealias Parameters = (any Hashable & Sendable, any Error & Sendable) -> any Equatable & Codable
        """,
      findings: []
    )
  }
}
