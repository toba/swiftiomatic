@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct UseAtCNotUnderscoreCDeclTests: RuleTesting {
  @Test func cdeclWithSymbolName() {
    assertFormatting(
      UseAtCNotUnderscoreCDecl.self,
      input: """
        1️⃣@_cdecl("my_symbol")
        func bar() {}
        """,
      expected: """
        @c("my_symbol")
        func bar() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '@_cdecl' with '@c'"),
      ]
    )
  }

  @Test func alreadyC() {
    assertFormatting(
      UseAtCNotUnderscoreCDecl.self,
      input: """
        @c("my_symbol")
        func bar() {}
        """,
      expected: """
        @c("my_symbol")
        func bar() {}
        """,
      findings: []
    )
  }

  @Test func otherAttributesNotModified() {
    assertFormatting(
      UseAtCNotUnderscoreCDecl.self,
      input: """
        @objc
        class Foo {}
        """,
      expected: """
        @objc
        class Foo {}
        """,
      findings: []
    )
  }
}
