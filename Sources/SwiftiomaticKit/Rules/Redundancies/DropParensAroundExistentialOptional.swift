import SwiftSyntax

/// Drop the parentheses around an existential or opaque type that an optional wraps.
///
/// Before SE-0521 the parentheses were load-bearing, because `any P?` did not parse. They now say
/// nothing, and they read as a one-element tuple to anyone who has not memorised the old rule.
///
/// The rule leaves a metatype alone. In `(any P).Type` the parentheses bind the metatype, so
/// removing them changes what the type means.
///
/// It leaves a protocol composition alone too. SE-0521 drops the parentheses for a single protocol,
/// so `(any P & Q)?` still needs them and `any P & Q?` does not compile.
///
/// Lint: An optional or implicitly unwrapped optional wrapping a parenthesised `any` or `some` type
/// raises a warning.
///
/// Rewrite: The parentheses are removed.
final class DropParensAroundExistentialOptional: StaticFormatRule<BasicRuleValue>,
    @unchecked Sendable
{
    static let rewriteOrder = 60

    override class var group: ConfigurationGroup? { .redundancies }

    static func transform(
        _ node: OptionalTypeSyntax,
        original _: OptionalTypeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> TypeSyntax {
        guard let inner = unwrappedExistential(node.wrappedType) else { return TypeSyntax(node) }
        Self.diagnose(.dropExistentialParens, on: node, context: context)
        return TypeSyntax(node.with(\.wrappedType, inner))
    }

    static func transform(
        _ node: ImplicitlyUnwrappedOptionalTypeSyntax,
        original _: ImplicitlyUnwrappedOptionalTypeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> TypeSyntax {
        guard let inner = unwrappedExistential(node.wrappedType) else { return TypeSyntax(node) }
        Self.diagnose(.dropExistentialParens, on: node, context: context)
        return TypeSyntax(node.with(\.wrappedType, inner))
    }

    /// The `any` or `some` type inside a bare one-element tuple, carrying the tuple's own trivia so
    /// the surrounding spacing survives.
    ///
    /// - Parameter type: the wrapped type of the optional
    /// - Returns: the inner type, or `nil` when the shape is anything else
    private static func unwrappedExistential(_ type: TypeSyntax) -> TypeSyntax? {
        guard let tuple = type.as(TupleTypeSyntax.self),
              let only = tuple.elements.firstAndOnly,
              // a label or an ellipsis makes it a real tuple element, not redundant parentheses
              only.firstName == nil,
              only.secondName == nil,
              only.ellipsis == nil,
              let existential = only.type.as(SomeOrAnyTypeSyntax.self),
              // SE-0521 drops the parentheses for one protocol only; a composition still needs them
              !existential.constraint.is(CompositionTypeSyntax.self) else { return nil }

        return only.type
            .with(\.leadingTrivia, tuple.leadingTrivia)
            .with(\.trailingTrivia, tuple.trailingTrivia)
    }
}

fileprivate extension Finding.Message {
    static var dropExistentialParens: Finding.Message {
        "remove the parentheses; 'any P?' and 'some P?' parse without them since SE-0521"
    }
}
