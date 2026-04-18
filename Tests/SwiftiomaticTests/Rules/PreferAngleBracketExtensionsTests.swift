@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct GenericExtensionsTests: RuleTesting {
  @Test func arrayWhereElement() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Array 1️⃣where Element == Foo {}
        """,
      expected: """
        extension Array<Foo> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Array' extension instead of 'where' clause"),
      ]
    )
  }

  @Test func optionalWhereWrapped() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Optional 1️⃣where Wrapped == Foo {}
        """,
      expected: """
        extension Optional<Foo> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Optional' extension instead of 'where' clause"),
      ]
    )
  }

  @Test func dictionaryWhereKeyValue() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Dictionary 1️⃣where Key == String, Value == Int {}
        """,
      expected: """
        extension Dictionary<String, Int> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Dictionary' extension instead of 'where' clause"),
      ]
    )
  }

  @Test func collectionWhereElement() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Collection 1️⃣where Element == Foo {}
        """,
      expected: """
        extension Collection<Foo> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Collection' extension instead of 'where' clause"),
      ]
    )
  }

  @Test func alreadyAngleBracket() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Array<Foo> {}
        """,
      expected: """
        extension Array<Foo> {}
        """,
      findings: []
    )
  }

  @Test func unknownType() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension MyCustomType where Element == Foo {}
        """,
      expected: """
        extension MyCustomType where Element == Foo {}
        """,
      findings: []
    )
  }

  @Test func conformanceConstraintNotFlagged() {
    // `Element: Foo` is a conformance, not same-type — can't use angle brackets
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Array where Element: Foo {}
        """,
      expected: """
        extension Array where Element: Foo {}
        """,
      findings: []
    )
  }

  @Test func dictionaryPartialConstraint() {
    // Only Key is constrained, not Value — can't use angle brackets
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Dictionary where Key == String {}
        """,
      expected: """
        extension Dictionary where Key == String {}
        """,
      findings: []
    )
  }

  @Test func noWhereClause() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Array {}
        """,
      expected: """
        extension Array {}
        """,
      findings: []
    )
  }

  @Test func dictionaryReversedOrder() {
    // Value constrained before Key — should still produce <String, Int>
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Dictionary 1️⃣where Value == Int, Key == String {}
        """,
      expected: """
        extension Dictionary<String, Int> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Dictionary' extension instead of 'where' clause"),
      ]
    )
  }

  // MARK: - Adapted from SwiftFormat

  @Test func genericTypeAsConstraintValue() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Array 1️⃣where Element == Foo<Bar> {}
        """,
      expected: """
        extension Array<Foo<Bar>> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Array' extension instead of 'where' clause"),
      ]
    )
  }

  @Test func preservesOtherConstraintsInWhereClause() {
    // Element consumed, Index == Int remains in where clause
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Collection 1️⃣where Element == String, Index == Int {}
        """,
      expected: """
        extension Collection<String> where Index == Int {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Collection' extension instead of 'where' clause"),
      ]
    )
  }

  @Test func nestedCollectionType() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Array 1️⃣where Element == [[Foo: Bar]] {}
        """,
      expected: """
        extension Array<[[Foo: Bar]]> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Array' extension instead of 'where' clause"),
      ]
    )
  }

  @Test func sequenceWhereElement() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Sequence 1️⃣where Element == Foo {}
        """,
      expected: """
        extension Sequence<Foo> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Sequence' extension instead of 'where' clause"),
      ]
    )
  }

  @Test func setWhereElement() {
    assertFormatting(
      PreferAngleBracketExtensions.self,
      input: """
        extension Set 1️⃣where Element == Foo {}
        """,
      expected: """
        extension Set<Foo> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use angle bracket syntax for 'Set' extension instead of 'where' clause"),
      ]
    )
  }
}
