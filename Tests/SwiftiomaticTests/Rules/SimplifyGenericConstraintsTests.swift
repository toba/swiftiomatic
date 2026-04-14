@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct SimplifyGenericConstraintsTests: RuleTesting {
  @Test func functionWithSimpleConstraint() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func process<T>(_ value: T) where 1️⃣T: Codable {}
        """,
      expected: """
        func process<T: Codable>(_ value: T) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func structWithSimpleConstraint() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Foo<T> where 1️⃣T: Hashable {}
        """,
      expected: """
        struct Foo<T: Hashable> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func multipleConstraints() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        struct Foo<T, U> where 1️⃣T: Hashable, 2️⃣U: Codable {}
        """,
      expected: """
        struct Foo<T: Hashable, U: Codable> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'T' can be simplified to an inline constraint"),
        FindingSpec("2️⃣", message: "constraint on 'U' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func sameTypeConstraintNotFlagged() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func foo<T>(_ value: T) where T == Int {}
        """,
      expected: """
        func foo<T>(_ value: T) where T == Int {}
        """,
      findings: []
    )
  }

  @Test func associatedTypeConstraintNotFlagged() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func foo<C: Collection>(_ c: C) where C.Element: Hashable {}
        """,
      expected: """
        func foo<C: Collection>(_ c: C) where C.Element: Hashable {}
        """,
      findings: []
    )
  }

  @Test func alreadyInlineNotFlagged() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func process<T: Codable>(_ value: T) {}
        """,
      expected: """
        func process<T: Codable>(_ value: T) {}
        """,
      findings: []
    )
  }

  @Test func noGenericParamsNotFlagged() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func process(_ value: Int) {}
        """,
      expected: """
        func process(_ value: Int) {}
        """,
      findings: []
    )
  }

  @Test func enumWithConstraint() {
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        enum Result<Value, Error> where 1️⃣Value: Decodable, 2️⃣Error: Swift.Error {}
        """,
      expected: """
        enum Result<Value: Decodable, Error: Swift.Error> {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'Value' can be simplified to an inline constraint"),
        FindingSpec("2️⃣", message: "constraint on 'Error' can be simplified to an inline constraint"),
      ]
    )
  }

  @Test func mixedConstraints() {
    // Only the simple conformance is inlined; the associated type constraint remains
    assertFormatting(
      SimplifyGenericConstraints.self,
      input: """
        func foo<C>(_ c: C) where 1️⃣C: Collection, C.Element: Hashable {}
        """,
      expected: """
        func foo<C: Collection>(_ c: C) where C.Element: Hashable {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "constraint on 'C' can be simplified to an inline constraint"),
      ]
    )
  }
}
