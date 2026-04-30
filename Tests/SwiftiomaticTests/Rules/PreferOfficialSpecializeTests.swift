@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct PreferOfficialSpecializeTests: RuleTesting {
  @Test func specializeWithWhereClause() {
    assertFormatting(
      PreferOfficialSpecialize.self,
      input: """
        1️⃣@_specialize(where T == Int)
        func foo<T>(_ x: T) {}
        """,
      expected: """
        @specialize(where T == Int)
        func foo<T>(_ x: T) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '@_specialize' with '@specialize'"),
      ]
    )
  }

  @Test func specializeWithExportedAndKind() {
    assertFormatting(
      PreferOfficialSpecialize.self,
      input: """
        1️⃣@_specialize(exported: true, kind: full, where T == Int)
        func foo<T>(_ x: T) {}
        """,
      expected: """
        @specialize(exported: true, kind: full, where T == Int)
        func foo<T>(_ x: T) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '@_specialize' with '@specialize'"),
      ]
    )
  }

  @Test func alreadySpecialize() {
    assertFormatting(
      PreferOfficialSpecialize.self,
      input: """
        @specialize(where T == Int)
        func foo<T>(_ x: T) {}
        """,
      expected: """
        @specialize(where T == Int)
        func foo<T>(_ x: T) {}
        """,
      findings: []
    )
  }

  @Test func otherAttributesNotModified() {
    assertFormatting(
      PreferOfficialSpecialize.self,
      input: """
        @inlinable
        func foo<T>(_ x: T) {}
        """,
      expected: """
        @inlinable
        func foo<T>(_ x: T) {}
        """,
      findings: []
    )
  }
}
