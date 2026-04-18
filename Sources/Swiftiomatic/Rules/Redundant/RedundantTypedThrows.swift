import SwiftSyntax

/// Simplify redundant typed throws annotations.
///
/// `throws(any Error)` is equivalent to plain `throws` and should be simplified.
/// `throws(Never)` means the function cannot throw and the throws clause should be removed.
///
/// Lint: If a redundant typed throws is found, a lint warning is raised.
///
/// Format: `throws(any Error)` is replaced with `throws`. `throws(Never)` is removed.
@_spi(Rules)
public final class RedundantTypedThrows: SyntaxFormatRule {
  public override class var group: ConfigGroup? { .removeRedundant }

  // Function declarations: `func foo() throws(any Error)`
  public override func visit(_ node: FunctionEffectSpecifiersSyntax) -> FunctionEffectSpecifiersSyntax {
    guard let throwsClause = node.throwsClause,
      let type = throwsClause.type
    else {
      return node
    }

    let trimmed = type.trimmedDescription

    if trimmed == "any Error" {
      diagnose(.replaceAnyErrorWithThrows, on: throwsClause)
      return node.with(\.throwsClause, simplifyToPlainThrows(throwsClause))
    }

    if trimmed == "Never" {
      diagnose(.removeThrowsNever, on: throwsClause)
      return node.with(\.throwsClause, nil)
    }

    return node
  }

  // Function types: `() throws(any Error) -> Void`
  public override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
    let visited = super.visit(node)
    guard let funcType = visited.as(FunctionTypeSyntax.self),
      let effectSpecifiers = funcType.effectSpecifiers,
      let throwsClause = effectSpecifiers.throwsClause,
      let type = throwsClause.type
    else {
      return visited
    }

    let trimmed = type.trimmedDescription

    if trimmed == "any Error" {
      diagnose(.replaceAnyErrorWithThrows, on: throwsClause)
      let simplified = simplifyToPlainThrows(throwsClause)
      return TypeSyntax(funcType.with(\.effectSpecifiers, effectSpecifiers.with(\.throwsClause, simplified)))
    }

    if trimmed == "Never" {
      diagnose(.removeThrowsNever, on: throwsClause)
      var newSpecs = effectSpecifiers
      newSpecs.throwsClause = nil
      if newSpecs.asyncSpecifier == nil {
        return TypeSyntax(funcType.with(\.effectSpecifiers, nil))
      }
      return TypeSyntax(funcType.with(\.effectSpecifiers, newSpecs))
    }

    return visited
  }

  /// Simplify `throws(any Error)` → `throws`, preserving trailing trivia from `)`.
  private func simplifyToPlainThrows(_ clause: ThrowsClauseSyntax) -> ThrowsClauseSyntax {
    let trailingTrivia = clause.rightParen?.trailingTrivia ?? []
    return clause
      .with(\.type, nil)
      .with(\.leftParen, nil)
      .with(\.rightParen, nil)
      .with(\.throwsSpecifier, clause.throwsSpecifier.with(\.trailingTrivia, trailingTrivia))
  }
}

extension Finding.Message {
  fileprivate static let replaceAnyErrorWithThrows: Finding.Message =
    "replace 'throws(any Error)' with 'throws'"

  fileprivate static let removeThrowsNever: Finding.Message =
    "remove 'throws(Never)'; the function cannot throw"
}
