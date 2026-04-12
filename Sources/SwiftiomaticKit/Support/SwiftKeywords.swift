import SwiftiomaticSyntax

/// Reserved keywords in Swift that require backtick escaping when used as identifiers.
///
/// Context-specific keywords (`async`, `lazy`, `mutating`, `some`, etc.) are excluded
/// because they behave like identifiers in most contexts.
private let swiftKeywords: Set<String> = [
  "let", "return", "func", "var", "if", "public", "as", "else", "in", "import",
  "class", "try", "guard", "case", "for", "init", "extension", "private", "static",
  "fileprivate", "internal", "switch", "do", "catch", "enum", "struct", "throws",
  "throw", "typealias", "where", "break", "deinit", "subscript", "is", "while",
  "associatedtype", "inout", "continue", "fallthrough", "operator", "precedencegroup",
  "repeat", "rethrows", "default", "protocol", "defer", "await", "consume", "discard",
]

extension String {
  /// Whether this string is a reserved keyword in Swift
  var isSwiftKeyword: Bool { swiftKeywords.contains(self) }
}
