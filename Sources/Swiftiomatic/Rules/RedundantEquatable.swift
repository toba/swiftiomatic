import SwiftSyntax

/// Flag hand-written `Equatable` conformance on structs and enums that qualify for
/// compiler-synthesized conformance.
///
/// The compiler synthesizes `Equatable` for structs (all stored properties are `Equatable`)
/// and enums (all associated values are `Equatable`). A manual `==` implementation that
/// simply compares all members in order is redundant.
///
/// This rule uses a heuristic: it flags `==` implementations on `Equatable` types where
/// the body is a single return statement comparing all stored properties with `&&`.
/// It does NOT perform type-checking — it relies on structural patterns.
///
/// This rule is opt-in due to the heuristic nature.
///
/// Lint: If a likely-redundant `Equatable` implementation is found, a lint warning is raised.
@_spi(Rules)
public final class RedundantEquatable: SyntaxLintRule {

  public override class var isOptIn: Bool { true }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    checkForRedundantEquatable(
      members: node.memberBlock.members,
      inheritanceClause: node.inheritanceClause
    )
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    checkForRedundantEquatable(
      members: node.memberBlock.members,
      inheritanceClause: node.inheritanceClause
    )
    return .visitChildren
  }

  private func checkForRedundantEquatable(
    members: MemberBlockItemListSyntax,
    inheritanceClause: InheritanceClauseSyntax?
  ) {
    // Must conform to Equatable.
    guard let inheritanceClause,
      inheritanceClause.inheritedTypes.contains(where: {
        $0.type.trimmedDescription == "Equatable"
      })
    else {
      return
    }

    // Find the `==` operator function.
    for member in members {
      guard let funcDecl = member.decl.as(FunctionDeclSyntax.self),
        funcDecl.modifiers.contains(anyOf: [.static]),
        funcDecl.name.text == "==",
        funcDecl.signature.parameterClause.parameters.count == 2,
        let body = funcDecl.body,
        isSingleReturnBody(body)
      else {
        continue
      }

      diagnose(.removeRedundantEquatable, on: funcDecl.name)
      return
    }
  }

  /// Returns `true` if the function body is a single return statement.
  private func isSingleReturnBody(_ body: CodeBlockSyntax) -> Bool {
    let statements = body.statements
    if statements.count == 1, let item = statements.first {
      // Single expression (implicit return)
      if item.item.is(ExprSyntax.self) { return true }
      // Explicit return
      if let returnStmt = item.item.as(StmtSyntax.self)?.as(ReturnStmtSyntax.self),
        returnStmt.expression != nil
      {
        return true
      }
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantEquatable: Finding.Message =
    "remove hand-written '==' operator; compiler-synthesized Equatable conformance is likely equivalent"
}
