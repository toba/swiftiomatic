import SwiftSyntax

/// Remove backticks around identifiers that are not reserved keywords.
///
/// Backticks are only needed when an identifier is a Swift keyword (e.g. `` `class` ``,
/// `` `func` ``, `` `return` ``). Contextual keywords like `async`, `await`, `some`, `any`
/// do not need backticks when used as identifiers.
///
/// Lint: If unnecessary backticks are found, a lint warning is raised.
@_spi(Rules)
public final class RedundantBackticks: SyntaxLintRule {

  /// The set of Swift keywords that always require backticks when used as identifiers.
  private static let reservedKeywords: Set<String> = [
    "Any", "as", "associatedtype", "break", "case", "catch", "class", "continue",
    "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough",
    "false", "fileprivate", "for", "func", "guard", "if", "import", "in", "init",
    "inout", "internal", "is", "let", "nil", "operator", "precedencegroup", "private",
    "protocol", "public", "repeat", "rethrows", "return", "self", "Self", "static",
    "struct", "subscript", "super", "switch", "throw", "throws", "true", "try",
    "typealias", "var", "where", "while",
  ]

  public override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
    // Only check identifier tokens.
    guard case .identifier(let text) = node.tokenKind else {
      return .visitChildren
    }

    // The identifier text includes backticks when escaped (e.g. "`name`").
    guard text.hasPrefix("`") && text.hasSuffix("`") && text.count > 2 else {
      return .visitChildren
    }

    // Strip backticks to get the bare name.
    let bareName = String(text.dropFirst().dropLast())

    // If it's not a reserved keyword, the backticks are redundant.
    if !Self.reservedKeywords.contains(bareName) {
      diagnose(.removeRedundantBackticks(name: bareName), on: node)
    }

    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantBackticks(name: String) -> Finding.Message {
    "remove unnecessary backticks around '\(name)'"
  }
}
