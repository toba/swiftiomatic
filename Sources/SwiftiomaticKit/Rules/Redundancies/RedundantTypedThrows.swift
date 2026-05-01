import SwiftSyntax

/// Simplify redundant typed throws annotations.
///
/// `throws(any Error)` is equivalent to plain `throws` and should be simplified. `throws(Never)`
/// means the function cannot throw and the throws clause should be removed.
///
/// Lint: If a redundant typed throws is found, a lint warning is raised.
///
/// Rewrite: `throws(any Error)` is replaced with `throws` . `throws(Never)` is removed.
final class RedundantTypedThrows: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    // Function declarations: `func foo() throws(any Error)`

    static func transform(
        _ node: FunctionEffectSpecifiersSyntax,
        parent _: Syntax?,
        context: Context
    ) -> FunctionEffectSpecifiersSyntax {
        guard let throwsClause = node.throwsClause,
              let type = throwsClause.type else { return node }

        let trimmed = type.trimmedDescription

        if trimmed == "any Error" {
            Self.diagnose(.replaceAnyErrorWithThrows, on: throwsClause, context: context)
            return node.with(\.throwsClause, simplifyToPlainThrows(throwsClause))
        }

        if trimmed == "Never" {
            Self.diagnose(.removeThrowsNever, on: throwsClause, context: context)
            return node.with(\.throwsClause, nil)
        }

        return node
    }

    // Function types: `() throws(any Error) -> Void`
    static func transform(
        _ funcType: FunctionTypeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> TypeSyntax {
        guard let effectSpecifiers = funcType.effectSpecifiers,
              let throwsClause = effectSpecifiers.throwsClause,
              let type = throwsClause.type else { return TypeSyntax(funcType) }

        let trimmed = type.trimmedDescription

        if trimmed == "any Error" {
            Self.diagnose(.replaceAnyErrorWithThrows, on: throwsClause, context: context)
            let simplified = simplifyToPlainThrows(throwsClause)
            return TypeSyntax(
                funcType.with(\.effectSpecifiers, effectSpecifiers.with(\.throwsClause, simplified))
            )
        }

        if trimmed == "Never" {
            Self.diagnose(.removeThrowsNever, on: throwsClause, context: context)
            var newSpecs = effectSpecifiers
            newSpecs.throwsClause = nil
            return newSpecs.asyncSpecifier == nil
                ? TypeSyntax(funcType.with(\.effectSpecifiers, nil))
                : TypeSyntax(funcType.with(\.effectSpecifiers, newSpecs))
        }

        return TypeSyntax(funcType)
    }

    /// Simplify `throws(any Error)` → `throws` , preserving trailing trivia from `)` .
    private static func simplifyToPlainThrows(_ clause: ThrowsClauseSyntax) -> ThrowsClauseSyntax {
        let trailingTrivia = clause.rightParen?.trailingTrivia ?? []
        return clause
            .with(\.type, nil)
            .with(\.leftParen, nil)
            .with(\.rightParen, nil)
            .with(\.throwsSpecifier, clause.throwsSpecifier.with(\.trailingTrivia, trailingTrivia))
    }
}

fileprivate extension Finding.Message {
    static let replaceAnyErrorWithThrows: Finding.Message =
        "replace 'throws(any Error)' with 'throws'"

    static let removeThrowsNever: Finding.Message =
        "remove 'throws(Never)'; the function cannot throw"
}
