import SwiftSyntax

/// Doc comments ( `///` and `/** */` ) inside function, initializer, and accessor bodies should be
/// regular comments ( `//` or `/* */` ).
///
/// Documentation comments are intended for API-level declarations. Inside an implementation body, a
/// doc comment cannot document anything externally visible, so a regular comment is the correct
/// form.
///
/// Nested function declarations are exempt — they are still declarations and may carry doc
/// comments.
///
/// Lint: If a doc comment appears inside a body, a lint warning is raised.
final class NoDocCommentsInsideFunctions: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override static var key: String { "noDocCommentsInsideFunctions" }
    override static var group: ConfigurationGroup? { .comments }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body { scanBody(body) }
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body { scanBody(body) }
        return .visitChildren
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body { scanBody(body) }
        return .visitChildren
    }

    override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body { scanBody(body) }
        return .visitChildren
    }

    private func scanBody(_ body: CodeBlockSyntax) {
        for token in body.tokens(viewMode: .sourceAccurate) {
            scanTrivia(
                token.leadingTrivia, on: token, isLeading: true,
                declToken: nestedDeclToken(for: token))
            scanTrivia(token.trailingTrivia, on: token, isLeading: false, declToken: nil)
        }
    }

    private func scanTrivia(
        _ trivia: Trivia,
        on token: TokenSyntax,
        isLeading: Bool,
        declToken: TokenSyntax?
    ) {
        // If the token is the leading token of a nested declaration that may carry a doc comment
        // (func/init/deinit/subscript/var/let/...), skip its leading trivia.
        if isLeading, declToken != nil { return }

        for index in trivia.indices {
            switch trivia[index] {
                case .docLineComment, .docBlockComment:
                    let anchor: FindingAnchor = isLeading
                        ? .leadingTrivia(index) : .trailingTrivia(index)
                    diagnose(.localDocComment, on: token, anchor: anchor)
                default: continue
            }
        }
    }

    /// Returns the token if it is the first token of a nested declaration whose doc comment should
    /// be preserved (currently: nested `func` ).
    private func nestedDeclToken(for token: TokenSyntax) -> TokenSyntax? {
        guard let parent = token.parent else { return nil }

        switch parent.kind {
            case .functionDecl:
                return parent.firstToken(viewMode: .sourceAccurate) == token ? token : nil
            default: return nil
        }
    }
}

fileprivate extension Finding.Message {
    static let localDocComment: Finding.Message =
        "use a regular comment (//) inside a function body, not a doc comment (///)"
}
