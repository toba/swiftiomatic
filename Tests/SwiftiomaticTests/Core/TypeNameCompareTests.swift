import SwiftParser
import SwiftSyntax
@testable import SwiftiomaticKit
import Testing

@Suite struct TypeNameCompareTests {
  /// Parses `source` and returns the inheritance clause of its single top-level type.
  private func clause(_ source: String) throws -> InheritanceClauseSyntax {
    let item = try #require(Parser.parse(source: source).statements.first?.item)
    let decl = try #require(item.asProtocol(DeclGroupSyntax.self))
    return try #require(decl.inheritanceClause)
  }

  private static let candidates = [
    "Foo", "XCTestCase", "Foundation.XCTestCase", "Foo<Int>", "`Foo`", "Sendable",
    "@unchecked Sendable", "any P", "[Int]", "",
  ]

  @Test func trimmedDescriptionEqualsMatchesStringCompare() throws {
    let source = """
      class C: Foo, Foundation.XCTestCase, Foo<Int>, `Foo`, @unchecked Sendable /* c */, [Int], \
      Foo /* note */ {}
      """
    for inherited in try clause(source).inheritedTypes {
      for candidate in Self.candidates {
        #expect(
          inherited.type.trimmedDescriptionEquals(candidate)
            == (inherited.type.trimmedDescription == candidate),
          "\(inherited.type.trimmedDescription) vs \(candidate)"
        )
      }
    }
  }

  /// A qualified name matches only its full spelling.
  @Test func qualifiedNameMatchesOnlyFullSpelling() throws {
    let qualified = try clause("class C: Foundation.XCTestCase {}")
    #expect(qualified.contains(named: "Foundation.XCTestCase"))
    #expect(!qualified.contains(named: "XCTestCase"))
    #expect(qualified.inherited(named: "XCTestCase") == nil)
    #expect(qualified.removing(named: "XCTestCase") == qualified)
  }

  @Test func genericNameMatchesOnlyFullSpelling() throws {
    let generic = try clause("struct S: Foo<Int> {}")
    #expect(generic.contains(named: "Foo<Int>"))
    #expect(!generic.contains(named: "Foo"))
  }

  @Test func plainNameMatches() throws {
    let plain = try clause("struct S: Equatable, Sendable {}")
    #expect(plain.contains(named: "Sendable"))
    #expect(plain.inherited(named: "Equatable") != nil)
    #expect(plain.removing(named: "Equatable")?.trimmedDescription == ": Sendable")
  }
}
