import SwiftSyntax

/// Prefer `[weak self]` over `[unowned self]` in closure capture lists.
///
/// `unowned` references crash when the captured object has been deallocated; `weak` returns `nil`
/// safely. Unless the closure's lifetime is provably shorter than the captured object's, `unowned`
/// is a latent crash waiting for a refactor to expose.
///
/// Lint: A warning is raised on any `unowned` keyword that appears in a closure capture list.
/// `unowned` stored properties (e.g. `unowned var owner: Foo` ) are not flagged.
final class UseWeakSelfInClosures: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .memory }

    override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        if case .keyword(.unowned) = node.tokenKind,
           node.parent?.is(ClosureCaptureSpecifierSyntax.self) == true
        {
            diagnose(.useWeakSelfInClosures, on: node)
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let useWeakSelfInClosures: Finding.Message =
        "prefer 'weak' over 'unowned' in closure captures to avoid crashes if the referent is deallocated"
}
