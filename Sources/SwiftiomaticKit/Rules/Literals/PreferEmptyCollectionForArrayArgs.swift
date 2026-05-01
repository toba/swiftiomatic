import SwiftSyntax

/// Suggest `EmptyCollection()` / `CollectionOfOne(x)` for `[]` and `[x]` array literals used as
/// function-call arguments.
///
/// When a callee accepts `some Collection` / `some Sequence` (or `any` of the same), passing an
/// array literal allocates a heap-backed `Array` . The two adapter types in the standard library
/// are zero-allocation alternatives.
///
/// This rule is lint-only and structural: it cannot see the parameter type, so it fires on every
/// empty/single-element array literal passed to a function. Default level is `.no` (opt-in) because
/// the false-positive rate is high in codebases that pass `Array` arguments by literal.
final class PreferEmptyCollectionForArrayArgs: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .literals }
    override class var defaultValue: LintOnlyValue { .init(lint: .no) }

    override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
        guard isFunctionCallArgument(node) else { return .visitChildren }

        switch node.elements.count {
            case 0: diagnose(.preferEmptyCollection, on: node)
            case 1: diagnose(.preferCollectionOfOne, on: node)
            default: break
        }
        return .visitChildren
    }

    private func isFunctionCallArgument(_ node: ArrayExprSyntax) -> Bool {
        guard let labeled = node.parent?.as(LabeledExprSyntax.self),
              labeled.parent?.is(LabeledExprListSyntax.self) == true,
              labeled.parent?.parent?.is(FunctionCallExprSyntax.self) == true else { return false }
        return true
    }
}

fileprivate extension Finding.Message {
    static let preferEmptyCollection: Finding.Message =
        "argument is an empty array literal — prefer 'EmptyCollection()' if the parameter accepts 'some Collection' / 'some Sequence'"
    static let preferCollectionOfOne: Finding.Message =
        "argument is a single-element array literal — prefer 'CollectionOfOne(x)' if the parameter accepts 'some Collection' / 'some Sequence'"
}
