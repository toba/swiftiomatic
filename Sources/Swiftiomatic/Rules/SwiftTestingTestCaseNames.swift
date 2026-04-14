import SwiftSyntax

/// Remove the `test` prefix from Swift Testing `@Test` function names.
///
/// In Swift Testing, test methods are identified by the `@Test` attribute, not by a naming
/// convention. The `test` prefix is redundant and should be removed for idiomatic Swift Testing.
///
/// The rename is skipped when:
/// - The remainder after removing `test` would be empty, start with a digit, or be a Swift keyword
/// - The new name would collide with an existing identifier in the same scope
///
/// Lint: A warning is raised for `@Test` functions with a `test` prefix.
///
/// Format: The `test` prefix is removed and the first letter is lowercased.
@_spi(Rules)
public final class SwiftTestingTestCaseNames: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  private var importsTesting = false
  private var allIdentifiers = Set<String>()

  private static let swiftKeywords: Set<String> = [
    "init", "deinit", "subscript", "nil", "true", "false", "self", "Self",
    "super", "class", "struct", "enum", "protocol", "extension", "func",
    "var", "let", "import", "return", "throw", "throws", "catch", "try",
    "if", "else", "for", "while", "do", "switch", "case", "default",
    "break", "continue", "fallthrough", "where", "guard", "in", "as", "is",
    "async", "await", "some", "any", "repeat", "defer", "typealias",
    "associatedtype", "operator", "precedencegroup", "inout", "static",
  ]

  public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    for stmt in node.statements {
      if let importDecl = stmt.item.as(ImportDeclSyntax.self),
        importDecl.path.first?.name.text == "Testing"
      {
        importsTesting = true
      }
    }

    // Collect identifiers for collision detection
    for token in node.tokens(viewMode: .sourceAccurate) {
      if case .identifier(let name) = token.tokenKind {
        allIdentifiers.insert(name)
      }
    }

    return super.visit(node)
  }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard importsTesting,
      node.hasAttribute("Test", inModule: "Testing")
    else {
      return DeclSyntax(node)
    }

    guard case .identifier(let rawIdent) = node.name.tokenKind else {
      return DeclSyntax(node)
    }

    let isBackticked = rawIdent.hasPrefix("`") && rawIdent.hasSuffix("`")
    let bareName = isBackticked ? String(rawIdent.dropFirst().dropLast()) : rawIdent

    let lowerName = bareName.lowercased()
    guard lowerName.hasPrefix("test") else {
      return DeclSyntax(node)
    }

    let newIdentifier: String
    if isBackticked {
      // `test something` → `something`, `Test Feature` → `Feature`
      let afterTest = bareName.dropFirst(4)
      guard !afterTest.isEmpty else { return DeclSyntax(node) }
      let trimmed = afterTest.hasPrefix(" ") ? String(afterTest.dropFirst()) : String(afterTest)
      guard !trimmed.isEmpty else { return DeclSyntax(node) }
      newIdentifier = "`\(trimmed)`"
    } else {
      // testMyFeature → myFeature
      let afterTest = bareName.dropFirst(4)
      guard !afterTest.isEmpty, let first = afterTest.first else { return DeclSyntax(node) }
      if first.isNumber { return DeclSyntax(node) }

      let remainder = first.lowercased() + afterTest.dropFirst()
      if Self.swiftKeywords.contains(remainder) { return DeclSyntax(node) }
      if allIdentifiers.contains(remainder) && remainder != bareName { return DeclSyntax(node) }
      newIdentifier = remainder
    }

    diagnose(.removeTestPrefix(oldName: bareName), on: node.name)

    return DeclSyntax(
      node.with(\.name, node.name.with(\.tokenKind, .identifier(newIdentifier)))
    )
  }
}

extension Finding.Message {
  fileprivate static func removeTestPrefix(oldName: String) -> Finding.Message {
    "remove 'test' prefix from '@Test' function '\(oldName)'"
  }
}
