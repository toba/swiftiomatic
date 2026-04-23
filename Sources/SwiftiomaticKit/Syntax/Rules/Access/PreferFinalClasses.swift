import SwiftSyntax

/// Prefer `final class` unless a class is designed for subclassing.
///
/// Classes should be `final` by default to communicate that they are not designed to be
/// subclassed. Classes are left non-final if they are `open`, have "Base" in the name,
/// have a comment mentioning "base" or "subclass", or are subclassed within the same file.
///
/// When a class is made `final`, any `open` members are converted to `public` since
/// `final` classes cannot have `open` members.
///
/// Lint: A non-final, non-open class declaration raises a warning.
///
/// Format: The `final` modifier is added and `open` members are converted to `public`.
final class PreferFinalClasses: RewriteSyntaxRule<BasicRuleValue> {
    override class var group: ConfigurationGroup? { .access }
  override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .no) }

  /// Class names that appear as a superclass in some class declaration within the file.
  private var subclassedNames = Set<String>()

  override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    subclassedNames = collectSubclassedNames(in: Syntax(node))
    return super.visit(node)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ClassDeclSyntax.self)

    // Already final
    if visited.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) }) {
      return DeclSyntax(visited)
    }

    // Open classes are designed for subclassing
    if visited.modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) }) {
      return DeclSyntax(visited)
    }

    // Name contains "Base" — convention for base classes
    if visited.name.text.contains("Base") {
      return DeclSyntax(visited)
    }

    // Comment mentions base class or subclassing
    if commentMentionsSubclassing(node) {
      return DeclSyntax(visited)
    }

    // Class is subclassed within this file
    if subclassedNames.contains(visited.name.text) {
      return DeclSyntax(visited)
    }

    diagnose(.preferFinalClass, on: visited.classKeyword)

    var result = visited

    // Add `final` modifier
    var finalModifier = DeclModifierSyntax(
      name: .keyword(.final, trailingTrivia: .space))

    if result.modifiers.isEmpty {
      finalModifier.leadingTrivia = result.classKeyword.leadingTrivia
      result.classKeyword.leadingTrivia = []
    }

    result.modifiers.append(finalModifier)

    // Convert `open` members to `public` (final classes can't have open members)
    result.memberBlock.members = convertOpenToPublic(in: result.memberBlock.members)

    return DeclSyntax(result)
  }

  // MARK: - Subclass detection

  /// Scans the syntax tree for class declarations and collects names used in inheritance clauses.
  private func collectSubclassedNames(in node: Syntax) -> Set<String> {
    var names = Set<String>()
    collectSubclassedNamesRecursive(in: node, into: &names)
    return names
  }

  private func collectSubclassedNamesRecursive(in node: Syntax, into names: inout Set<String>) {
    if let classDecl = node.as(ClassDeclSyntax.self),
      let inheritanceClause = classDecl.inheritanceClause
    {
      for inherited in inheritanceClause.inheritedTypes {
        if let identType = inherited.type.as(IdentifierTypeSyntax.self) {
          names.insert(identType.name.text)
        }
      }
    }
    for child in node.children(viewMode: .sourceAccurate) {
      collectSubclassedNamesRecursive(in: child, into: &names)
    }
  }

  // MARK: - Doc comment detection

  /// Returns true if any comment in the leading trivia mentions "base" or "subclass".
  private func commentMentionsSubclassing(_ node: ClassDeclSyntax) -> Bool {
    let text =
      node.leadingTrivia.pieces
      .compactMap { piece -> String? in
        switch piece {
        case .docLineComment(let t), .docBlockComment(let t), .lineComment(let t),
          .blockComment(let t):
          return t
        default: return nil
        }
      }
      .joined()
      .lowercased()

    return text.contains("base") || text.contains("subclass")
  }

  // MARK: - Open → public conversion

  /// Replaces `open` modifiers with `public` on direct members of a class.
  private func convertOpenToPublic(
    in members: MemberBlockItemListSyntax
  ) -> MemberBlockItemListSyntax {
    MemberBlockItemListSyntax(
      members.map { member in
        guard let modified = replaceOpenModifier(in: member.decl) else { return member }
        var result = member
        result.decl = modified
        return result
      })
  }

  private func replaceOpenModifier(in decl: DeclSyntax) -> DeclSyntax? {
    if var d = decl.as(FunctionDeclSyntax.self), let m = openToPublic(d.modifiers) {
      d.modifiers = m; return DeclSyntax(d)
    }
    if var d = decl.as(VariableDeclSyntax.self), let m = openToPublic(d.modifiers) {
      d.modifiers = m; return DeclSyntax(d)
    }
    if var d = decl.as(SubscriptDeclSyntax.self), let m = openToPublic(d.modifiers) {
      d.modifiers = m; return DeclSyntax(d)
    }
    if var d = decl.as(InitializerDeclSyntax.self), let m = openToPublic(d.modifiers) {
      d.modifiers = m; return DeclSyntax(d)
    }
    if var d = decl.as(TypeAliasDeclSyntax.self), let m = openToPublic(d.modifiers) {
      d.modifiers = m; return DeclSyntax(d)
    }
    return nil
  }

  /// Returns a new modifier list with `open` replaced by `public`, or nil if no change needed.
  private func openToPublic(_ modifiers: DeclModifierListSyntax) -> DeclModifierListSyntax? {
    guard modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) }) else { return nil }
    return DeclModifierListSyntax(
      modifiers.map { mod in
        guard mod.name.tokenKind == .keyword(.open) else { return mod }
        return mod.with(
          \.name,
          .keyword(
            .public,
            leadingTrivia: mod.name.leadingTrivia,
            trailingTrivia: mod.name.trailingTrivia
          ))
      })
  }
}

extension Finding.Message {
  fileprivate static let preferFinalClass: Finding.Message =
    "prefer 'final class' unless designed for subclassing"
}
