import SwiftSyntax

/// Remove `@Suite` attributes that have no arguments, since they are inferred by the Swift Testing
/// framework.
///
/// `@Suite` with no arguments (or empty parentheses) is redundant — Swift Testing automatically
/// discovers test suites without explicit annotation. Only `@Suite` with arguments like
/// `@Suite(.serialized)` or `@Suite("Display Name")` should be kept.
///
/// Lint: A warning is raised when `@Suite` or `@Suite()` is used without arguments.
///
/// Format: The redundant `@Suite` attribute is removed.
@_spi(Rules)
public final class RedundantSwiftTestingSuite: SyntaxFormatRule {
  public override class var group: ConfigGroup? { .removeRedundant }

  public override class var isOptIn: Bool { true }

  private var importsTesting = false

  public override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    if node.path.first?.name.text == "Testing" {
      importsTesting = true
    }
    return DeclSyntax(node)
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantSuite(from: node, keyword: \.structKeyword))
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantSuite(from: node, keyword: \.classKeyword))
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantSuite(from: node, keyword: \.enumKeyword))
  }

  public override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantSuite(from: node, keyword: \.actorKeyword))
  }

  private func removeRedundantSuite<Decl: DeclSyntaxProtocol & WithAttributesSyntax>(
    from node: Decl,
    keyword: WritableKeyPath<Decl, TokenSyntax>
  ) -> Decl {
    guard importsTesting,
      let attr = node.attributes.attribute(named: "Suite"),
      isRedundant(attr)
    else { return node }

    diagnose(.removeRedundantSuite, on: attr)

    var result = node
    let savedTrivia = attr.leadingTrivia
    result.attributes.remove(named: "Suite")
    if result.attributes.isEmpty {
      result[keyPath: keyword].leadingTrivia = savedTrivia
    }
    return result
  }

  private func isRedundant(_ attr: AttributeSyntax) -> Bool {
    if attr.arguments == nil { return true }
    if case let .argumentList(args) = attr.arguments, args.isEmpty { return true }
    return false
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantSuite: Finding.Message =
    "remove redundant '@Suite' attribute; it is inferred by Swift Testing"
}
