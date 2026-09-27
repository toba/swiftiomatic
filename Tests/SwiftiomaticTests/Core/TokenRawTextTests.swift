import SwiftParser
import SwiftSyntax
@testable import SwiftiomaticKit
import Testing

@Suite struct TokenRawTextTests {
  /// Returns every token in `source` whose text is not empty.
  private func tokens(_ source: String) -> [TokenSyntax] {
    Parser.parse(source: source).tokens(viewMode: .sourceAccurate).filter { !$0.text.isEmpty }
  }

  @Test func matchesSameTextAsStringCompare() {
    let literals: [StaticString] = [
      "let", "x", "foo", "`foo`", "=", "!", "count", "isEmpty", "aVeryLongIdentifierName", "é", "",
    ]
    let source = "let x = foo.count; let `foo` = !aVeryLongIdentifierName.isEmpty; let é = 1"
    for token in tokens(source) {
      for literal in literals {
        #expect(token.hasText(literal) == (token.text == literal.description))
      }
    }
  }

  @Test func backtickedIdentifierKeepsBackticks() throws {
    let token = try #require(tokens("let `foo` = 1").first { $0.text.contains("foo") })
    #expect(token.hasText("`foo`"))
    #expect(!token.hasText("foo"))
  }

  @Test func prefixMatchesLikeStringHasPrefix() throws {
    let token = try #require(tokens("let _cdeclThing = 1").first { $0.text.hasPrefix("_") })
    #expect(token.hasTextPrefix("_cdecl"))
    #expect(token.hasTextPrefix(""))
    #expect(!token.hasTextPrefix("cdecl"))
  }

  // MARK: - Line feed scan

  /// Sources whose nodes cover line feeds in trivia, in comments, in multi-line strings, and in
  /// carriage-return line-feed pairs.
  private static let lineFeedSources = [
    "foo(a, b)",
    "foo(\n  a,\n  b\n)",
    "\n\nfoo(a) // c\n",
    "foo(a /* one\ntwo */, b)",
    "foo(\"\"\"\n  text\n  \"\"\")",
    "foo(\r\n  a\r\n)",
    "foo(a)\r\n",
    "foo(\r  a\r)",
    "let x = 1\nfoo(\n\ta)\n",
  ]

  @Test(arguments: lineFeedSources)
  func lineFeedScanMatchesDescription(source: String) {
    for node in Parser.parse(source: source).descendants() {
      #expect(node.descriptionContainsLineFeed() == node.description.contains("\n"))
      #expect(
        node.trimmedDescriptionContainsLineFeed() == node.trimmedDescription.contains("\n"),
        "\(node.kind): \(node.debugDescription)"
      )
    }
  }
}

private extension SyntaxProtocol {
  /// This node and every node below it.
  func descendants() -> [Syntax] {
    [Syntax(self)] + children(viewMode: .sourceAccurate).flatMap { $0.descendants() }
  }
}
