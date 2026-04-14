import SwiftSyntax

/// Convert types hosting only static members into enums.
///
/// An empty enum is the canonical way to create a namespace in Swift because it cannot
/// be instantiated. Structs and classes that contain only static members serve the same
/// purpose but can be accidentally instantiated.
///
/// This rule skips types with inheritance clauses, attributes, generic parameters,
/// initializers, or any instance members.
///
/// Lint: A struct or final class containing only static members raises a warning.
///
/// Format: The `struct` or `final class` keyword is replaced with `enum`.
@_spi(Rules)
public final class EnumNamespaces: SyntaxFormatRule {

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(StructDeclSyntax.self)
    guard shouldBeEnum(
      attributes: visited.attributes,
      inheritanceClause: visited.inheritanceClause,
      genericParameterClause: visited.genericParameterClause,
      genericWhereClause: visited.genericWhereClause,
      members: visited.memberBlock.members
    ) else {
      return DeclSyntax(visited)
    }

    diagnose(.useEnumNamespace, on: visited.name)

    let enumDecl = EnumDeclSyntax(
      leadingTrivia: visited.leadingTrivia,
      modifiers: visited.modifiers,
      enumKeyword: .keyword(
        .enum,
        leadingTrivia: visited.structKeyword.leadingTrivia,
        trailingTrivia: visited.structKeyword.trailingTrivia
      ),
      name: visited.name,
      memberBlock: visited.memberBlock,
      trailingTrivia: visited.trailingTrivia
    )
    return DeclSyntax(enumDecl)
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ClassDeclSyntax.self)

    // Only final classes can be converted — non-final classes might be subclassed
    let isFinal = visited.modifiers.contains { $0.name.tokenKind == .keyword(.final) }
    guard isFinal else { return DeclSyntax(visited) }

    guard shouldBeEnum(
      attributes: visited.attributes,
      inheritanceClause: visited.inheritanceClause,
      genericParameterClause: visited.genericParameterClause,
      genericWhereClause: visited.genericWhereClause,
      members: visited.memberBlock.members
    ) else {
      return DeclSyntax(visited)
    }

    diagnose(.useEnumNamespace, on: visited.name)

    // Remove the `final` modifier, transferring its trivia to the enum keyword
    let modifiersWithoutFinal = visited.modifiers.filter { $0.name.tokenKind != .keyword(.final) }

    let enumDecl = EnumDeclSyntax(
      leadingTrivia: visited.leadingTrivia,
      modifiers: DeclModifierListSyntax(modifiersWithoutFinal),
      enumKeyword: .keyword(
        .enum,
        leadingTrivia: visited.classKeyword.leadingTrivia,
        trailingTrivia: visited.classKeyword.trailingTrivia
      ),
      name: visited.name,
      memberBlock: visited.memberBlock,
      trailingTrivia: visited.trailingTrivia
    )
    return DeclSyntax(enumDecl)
  }

  private func shouldBeEnum(
    attributes: AttributeListSyntax,
    inheritanceClause: InheritanceClauseSyntax?,
    genericParameterClause: GenericParameterClauseSyntax?,
    genericWhereClause: GenericWhereClauseSyntax?,
    members: MemberBlockItemListSyntax
  ) -> Bool {
    guard attributes.isEmpty else { return false }
    guard inheritanceClause == nil else { return false }
    guard genericParameterClause == nil, genericWhereClause == nil else { return false }
    guard !members.isEmpty else { return false }
    return members.allSatisfy { hostsOnlyStaticContent($0.decl) }
  }

  private func hostsOnlyStaticContent(_ decl: DeclSyntax) -> Bool {
    if decl.is(StructDeclSyntax.self) || decl.is(ClassDeclSyntax.self)
      || decl.is(EnumDeclSyntax.self) || decl.is(ActorDeclSyntax.self)
      || decl.is(ProtocolDeclSyntax.self) || decl.is(TypeAliasDeclSyntax.self)
    {
      return true
    }
    if decl.is(InitializerDeclSyntax.self) { return false }
    if let varDecl = decl.as(VariableDeclSyntax.self) {
      return hasStaticModifier(varDecl.modifiers)
    }
    if let funcDecl = decl.as(FunctionDeclSyntax.self) {
      return hasStaticModifier(funcDecl.modifiers)
    }
    if let subDecl = decl.as(SubscriptDeclSyntax.self) {
      return hasStaticModifier(subDecl.modifiers)
    }
    if let ifConfig = decl.as(IfConfigDeclSyntax.self) {
      return ifConfig.clauses.allSatisfy { clause in
        guard let elements = clause.elements?.as(MemberBlockItemListSyntax.self) else {
          return true
        }
        return elements.allSatisfy { hostsOnlyStaticContent($0.decl) }
      }
    }
    return true
  }

  private func hasStaticModifier(_ modifiers: DeclModifierListSyntax) -> Bool {
    modifiers.contains { $0.name.tokenKind == .keyword(.static) }
  }
}

extension Finding.Message {
  fileprivate static let useEnumNamespace: Finding.Message =
    "use 'enum' instead of 'struct' or 'class' for types with only static members"
}
