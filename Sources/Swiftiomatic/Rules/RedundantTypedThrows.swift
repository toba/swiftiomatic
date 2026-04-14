import SwiftSyntax

/// Simplify redundant typed throws annotations.
///
/// `throws(any Error)` is equivalent to plain `throws` and should be simplified.
/// `throws(Never)` means the function cannot throw and the throws clause should be removed.
///
/// Lint: If a redundant typed throws is found, a lint warning is raised.
@_spi(Rules)
public final class RedundantTypedThrows: SyntaxLintRule {

  public override func visit(_ node: ThrowsClauseSyntax) -> SyntaxVisitorContinueKind {
    guard let type = node.type else {
      // Plain `throws` — nothing to do.
      return .skipChildren
    }

    let trimmed = type.trimmedDescription

    // `throws(any Error)` → `throws`
    if trimmed == "any Error" {
      diagnose(.replaceAnyErrorWithThrows, on: node)
      return .skipChildren
    }

    // `throws(Never)` → remove throws entirely
    if trimmed == "Never" {
      diagnose(.removeThrowsNever, on: node)
      return .skipChildren
    }

    return .skipChildren
  }
}

extension Finding.Message {
  fileprivate static let replaceAnyErrorWithThrows: Finding.Message =
    "replace 'throws(any Error)' with 'throws'"

  fileprivate static let removeThrowsNever: Finding.Message =
    "remove 'throws(Never)'; the function cannot throw"
}
