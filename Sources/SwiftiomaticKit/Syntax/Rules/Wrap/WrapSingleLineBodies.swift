import SwiftSyntax

/// Controls whether single-statement bodies are kept inline or wrapped to
/// multiple lines.
///
/// **Wrap mode** (default): Single-line bodies in conditionals, functions,
/// loops, and properties are expanded onto multiple lines.
///
/// **Inline mode**: Multi-line single-statement bodies are collapsed onto the
/// same line as the declaration, provided the result fits within the configured
/// line length.
///
/// Lint: A body whose formatting doesn't match the mode raises a warning.
///
/// Format: The body is wrapped or inlined to match the mode.
final class WrapSingleLineBodies: RewriteSyntaxRule<SingleLineBodiesConfiguration> {
    override class var key: String { "singleLineBodies" }
    override class var defaultValue: SingleLineBodiesConfiguration {
        var config = SingleLineBodiesConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }
    override class var group: ConfigurationGroup? { .wrap }

    private var mode: SingleLineBodiesConfiguration.Mode {
        context.configuration[WrapSingleLineBodies.self].mode
    }

    private var maxLength: Int { context.configuration[LineLength.self] }

    // MARK: - Wrap-mode state

    /// Tracks the current body indentation for nested inline structures.
    private var currentIndent = ""

    /// Tracks the base indentation for if/else-if chains so that `else if` bodies
    /// use the same base as the outermost `if`.
    private var chainBaseIndent: String?

    // MARK: - Conditionals

    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        switch mode {
        case .wrap: return wrapIf(node)
        case .inline: return inlineIf(node)
        }
    }

    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        switch mode {
        case .wrap: return wrapGuard(node)
        case .inline: return inlineGuard(node)
        }
    }

    // MARK: - Functions

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        switch mode {
        case .wrap: return wrapFunction(node)
        case .inline: return inlineFunction(node)
        }
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        switch mode {
        case .wrap: return wrapInit(node)
        case .inline: return inlineInit(node)
        }
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        switch mode {
        case .wrap: return wrapSubscript(node)
        case .inline: return inlineSubscript(node)
        }
    }

    // MARK: - Loops

    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        switch mode {
        case .wrap: return wrapFor(node)
        case .inline: return inlineFor(node)
        }
    }

    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        switch mode {
        case .wrap: return wrapWhile(node)
        case .inline: return inlineWhile(node)
        }
    }

    override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
        switch mode {
        case .wrap: return wrapRepeat(node)
        case .inline: return inlineRepeat(node)
        }
    }

    // MARK: - Properties

    override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
        switch mode {
        case .wrap: return wrapProperty(node)
        case .inline: return inlineProperty(node)
        }
    }
}

// MARK: - Wrap Mode

extension WrapSingleLineBodies {

    private func wrapIf(_ node: IfExprSyntax) -> ExprSyntax {
        let isElseIf = node.parent?.is(IfExprSyntax.self) == true

        let baseIndent: String
        if isElseIf, let chainIndent = chainBaseIndent {
            baseIndent = chainIndent
        } else {
            baseIndent = resolveIndent(from: node.ifKeyword.leadingTrivia)
        }

        let savedChainIndent = chainBaseIndent
        let savedIndent = currentIndent
        chainBaseIndent = baseIndent
        currentIndent = baseIndent + "    "
        defer {
            currentIndent = savedIndent
            chainBaseIndent = savedChainIndent
        }

        let needsBodyWrap = node.body.bodyNeedsWrapping
        if needsBodyWrap {
            diagnose(.wrapConditionalBody, on: node.body.leftBrace)
        }

        var result = node
        result.body.statements = visit(node.body.statements)
        if needsBodyWrap {
            result.body = result.body.wrappingBody(baseIndent: baseIndent)
        }

        if let elseBody = node.elseBody {
            switch elseBody {
            case .ifExpr(let nestedIf):
                result.elseBody = .ifExpr(visit(nestedIf).cast(IfExprSyntax.self))
            case .codeBlock(var block):
                let needsElseWrap = block.bodyNeedsWrapping
                if needsElseWrap {
                    diagnose(.wrapConditionalBody, on: block.leftBrace)
                }
                block.statements = visit(block.statements)
                if needsElseWrap {
                    block = block.wrappingBody(baseIndent: baseIndent)
                }
                result.elseBody = .codeBlock(block)
            }
        }

        return ExprSyntax(result)
    }

    private func wrapGuard(_ node: GuardStmtSyntax) -> StmtSyntax {
        let baseIndent = resolveIndent(from: node.guardKeyword.leadingTrivia)

        let savedIndent = currentIndent
        currentIndent = baseIndent + "    "
        defer { currentIndent = savedIndent }

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap {
            diagnose(.wrapConditionalBody, on: node.body.leftBrace)
        }

        var result = node
        result.body.statements = visit(node.body.statements)
        if needsWrap {
            result.body = result.body.wrappingBody(baseIndent: baseIndent)
        }
        return StmtSyntax(result)
    }

    private func wrapFunction(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard let body = node.body, body.bodyNeedsWrapping else { return super.visit(node) }

        diagnose(.wrapFunctionBody, on: body.leftBrace)

        let baseIndent = node.funcKeyword.leadingTrivia.indentation
        var result = node
        result.body = body.wrappingBody(baseIndent: baseIndent)
        return DeclSyntax(result)
    }

    private func wrapInit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        guard let body = node.body, body.bodyNeedsWrapping else { return super.visit(node) }

        diagnose(.wrapFunctionBody, on: body.leftBrace)

        let baseIndent = node.initKeyword.leadingTrivia.indentation
        var result = node
        result.body = body.wrappingBody(baseIndent: baseIndent)
        return DeclSyntax(result)
    }

    private func wrapSubscript(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        guard let accessorBlock = node.accessorBlock,
            case .getter(let statements) = accessorBlock.accessors,
            !statements.isEmpty
        else { return super.visit(node) }

        guard let firstStmt = statements.first,
            !firstStmt.leadingTrivia.containsNewlines
        else { return super.visit(node) }

        let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
        guard !closingOnNewLine else { return super.visit(node) }

        diagnose(.wrapFunctionBody, on: accessorBlock.leftBrace)

        let baseIndent = node.subscriptKeyword.leadingTrivia.indentation
        let bodyIndent = baseIndent + "    "

        var result = node
        var block = accessorBlock

        block.leftBrace = block.leftBrace.with(
            \.trailingTrivia,
            block.leftBrace.trailingTrivia.trimmingTrailingWhitespace
        )

        var items = Array(statements)
        items[0].leadingTrivia = .newline + Trivia(stringLiteral: bodyIndent)
        let lastIdx = items.count - 1
        items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia.trimmingTrailingWhitespace
        block.accessors = .getter(CodeBlockItemListSyntax(items))

        block.rightBrace = block.rightBrace.with(
            \.leadingTrivia,
            .newline + Trivia(stringLiteral: baseIndent)
        )

        result.accessorBlock = block
        return DeclSyntax(result)
    }

    private func wrapFor(_ node: ForStmtSyntax) -> StmtSyntax {
        let baseIndent = resolveIndent(from: node.forKeyword.leadingTrivia)

        let savedIndent = currentIndent
        currentIndent = baseIndent + "    "
        defer { currentIndent = savedIndent }

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap {
            diagnose(.wrapLoopBody, on: node.body.leftBrace)
        }

        var result = node
        result.body.statements = visit(node.body.statements)
        if needsWrap {
            result.body = result.body.wrappingBody(baseIndent: baseIndent)
        }
        return StmtSyntax(result)
    }

    private func wrapWhile(_ node: WhileStmtSyntax) -> StmtSyntax {
        let baseIndent = resolveIndent(from: node.whileKeyword.leadingTrivia)

        let savedIndent = currentIndent
        currentIndent = baseIndent + "    "
        defer { currentIndent = savedIndent }

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap {
            diagnose(.wrapLoopBody, on: node.body.leftBrace)
        }

        var result = node
        result.body.statements = visit(node.body.statements)
        if needsWrap {
            result.body = result.body.wrappingBody(baseIndent: baseIndent)
        }
        return StmtSyntax(result)
    }

    private func wrapRepeat(_ node: RepeatStmtSyntax) -> StmtSyntax {
        let baseIndent = resolveIndent(from: node.repeatKeyword.leadingTrivia)

        let savedIndent = currentIndent
        currentIndent = baseIndent + "    "
        defer { currentIndent = savedIndent }

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap {
            diagnose(.wrapLoopBody, on: node.body.leftBrace)
        }

        var result = node
        result.body.statements = visit(node.body.statements)
        if needsWrap {
            result.body = result.body.wrappingBody(baseIndent: baseIndent)
        }
        return StmtSyntax(result)
    }

    private func wrapProperty(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
        guard let accessorBlock = node.accessorBlock else { return node }

        switch accessorBlock.accessors {
        case .getter(let statements):
            guard !statements.isEmpty else { return node }
            guard let firstStmt = statements.first,
                !firstStmt.leadingTrivia.containsNewlines
            else { return node }
            let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
            guard !closingOnNewLine else { return node }

            diagnose(.wrapPropertyBody, on: accessorBlock.leftBrace)

            let baseIndent = resolveVarIndent(node)
            let bodyIndent = baseIndent + "    "

            var result = node
            var block = accessorBlock

            block.leftBrace = block.leftBrace.with(
                \.trailingTrivia,
                block.leftBrace.trailingTrivia.trimmingTrailingWhitespace
            )

            var items = Array(statements)
            items[0].leadingTrivia = .newline + Trivia(stringLiteral: bodyIndent)
            let lastIdx = items.count - 1
            items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia.trimmingTrailingWhitespace
            block.accessors = .getter(CodeBlockItemListSyntax(items))

            block.rightBrace = block.rightBrace.with(
                \.leadingTrivia,
                .newline + Trivia(stringLiteral: baseIndent)
            )

            result.accessorBlock = block
            return result

        case .accessors(let accessors):
            guard accessors.contains(where: { $0.body != nil }) else { return node }

            guard let firstAccessor = accessors.first,
                !firstAccessor.leadingTrivia.containsNewlines
            else { return node }
            let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
            guard !closingOnNewLine else { return node }

            diagnose(.wrapPropertyBody, on: accessorBlock.leftBrace)

            let baseIndent = resolveVarIndent(node)
            let bodyIndent = baseIndent + "    "

            var result = node
            var block = accessorBlock

            block.leftBrace = block.leftBrace.with(
                \.trailingTrivia,
                block.leftBrace.trailingTrivia.trimmingTrailingWhitespace
            )

            var items = Array(accessors)
            items[0].leadingTrivia = .newline + Trivia(stringLiteral: bodyIndent)
            let lastIdx = items.count - 1
            items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia.trimmingTrailingWhitespace
            block.accessors = .accessors(AccessorDeclListSyntax(items))

            block.rightBrace = block.rightBrace.with(
                \.leadingTrivia,
                .newline + Trivia(stringLiteral: baseIndent)
            )

            result.accessorBlock = block
            return result
        }
    }
}

// MARK: - Inline Mode

extension WrapSingleLineBodies {

    /// Whether a code block is already inline (body and closing brace on same line as opening brace).
    private func isAlreadyInline(_ body: CodeBlockSyntax) -> Bool {
        guard let firstStmt = body.statements.first else { return true }
        return !firstStmt.leadingTrivia.containsNewlines
            && !body.rightBrace.leadingTrivia.containsNewlines
    }

    /// Whether a code block has exactly one statement and is wrapped across multiple lines.
    private func canInline(_ body: CodeBlockSyntax) -> Bool {
        guard body.statements.count == 1 else { return false }
        return !isAlreadyInline(body)
    }

    /// Computes the length of a declaration line prefix up to (but not including) the body.
    /// Uses the leading trivia indentation + text from the first token to the left brace.
    private func prefixLength(from startToken: TokenSyntax, to leftBrace: TokenSyntax) -> Int {
        let indent = startToken.leadingTrivia.indentation
        // From the start of the line (after indent) to the left brace, inclusive.
        let startPos = startToken.positionAfterSkippingLeadingTrivia
        let braceEndPos = leftBrace.endPositionBeforeTrailingTrivia
        let textLength = braceEndPos.utf8Offset - startPos.utf8Offset
        return indent.count + textLength
    }

    /// Returns the trimmed body text for a single-statement code block.
    private func singleStatementText(_ body: CodeBlockSyntax) -> String {
        body.statements.first!.trimmedDescription
    }

    /// Checks if inlining the body would fit within the max line length.
    /// The inline form is: `<prefix> { <body> }<suffix>`
    private func fitsInline(
        prefixLength: Int,
        bodyText: String,
        suffixLength: Int = 0
    ) -> Bool {
        // "{ " + body + " }" = body.count + 4
        let totalLength = prefixLength + 2 + bodyText.count + 2 + suffixLength
        return totalLength <= maxLength
    }

    /// Returns a copy of the code block with the body inlined.
    private func inliningBody(_ body: CodeBlockSyntax) -> CodeBlockSyntax {
        var result = body
        result.leftBrace = result.leftBrace.with(\.trailingTrivia, .space)

        var items = Array(result.statements)
        items[0].leadingTrivia = []
        let lastIdx = items.count - 1
        items[lastIdx].trailingTrivia = []
        result.statements = CodeBlockItemListSyntax(items)

        result.rightBrace = result.rightBrace.with(\.leadingTrivia, .space)
        return result
    }

    // MARK: - Inline visitors

    private func inlineIf(_ node: IfExprSyntax) -> ExprSyntax {
        // For inline mode, only handle simple single-body if statements (no else chains)
        guard node.elseBody == nil else { return super.visit(node) }
        guard canInline(node.body) else { return super.visit(node) }

        let startToken = node.ifKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText) else {
            return super.visit(node)
        }

        diagnose(.inlineConditionalBody, on: node.body.leftBrace)

        var result = node
        result.body = inliningBody(node.body)
        return ExprSyntax(result)
    }

    private func inlineGuard(_ node: GuardStmtSyntax) -> StmtSyntax {
        guard canInline(node.body) else { return super.visit(node) }

        let startToken = node.guardKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText) else {
            return super.visit(node)
        }

        diagnose(.inlineConditionalBody, on: node.body.leftBrace)

        var result = node
        result.body = inliningBody(node.body)
        return StmtSyntax(result)
    }

    private func inlineFunction(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard let body = node.body, canInline(body) else { return super.visit(node) }

        let startToken = node.funcKeyword
        let bodyText = singleStatementText(body)
        let prefix = prefixLength(from: startToken, to: body.leftBrace)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText) else {
            return super.visit(node)
        }

        diagnose(.inlineFunctionBody, on: body.leftBrace)

        var result = node
        result.body = inliningBody(body)
        return DeclSyntax(result)
    }

    private func inlineInit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        guard let body = node.body, canInline(body) else { return super.visit(node) }

        let startToken = node.initKeyword
        let bodyText = singleStatementText(body)
        let prefix = prefixLength(from: startToken, to: body.leftBrace)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText) else {
            return super.visit(node)
        }

        diagnose(.inlineFunctionBody, on: body.leftBrace)

        var result = node
        result.body = inliningBody(body)
        return DeclSyntax(result)
    }

    private func inlineSubscript(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        guard let accessorBlock = node.accessorBlock,
            case .getter(let statements) = accessorBlock.accessors,
            statements.count == 1
        else { return super.visit(node) }

        // Must be wrapped (not already inline)
        guard let firstStmt = statements.first,
            firstStmt.leadingTrivia.containsNewlines
        else { return super.visit(node) }

        let startToken = node.subscriptKeyword
        let bodyText = firstStmt.trimmedDescription
        let prefix = prefixLength(from: startToken, to: accessorBlock.leftBrace)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText) else {
            return super.visit(node)
        }

        diagnose(.inlineFunctionBody, on: accessorBlock.leftBrace)

        var result = node
        var block = accessorBlock
        block.leftBrace = block.leftBrace.with(\.trailingTrivia, .space)
        var items = Array(statements)
        items[0].leadingTrivia = []
        items[0].trailingTrivia = []
        block.accessors = .getter(CodeBlockItemListSyntax(items))
        block.rightBrace = block.rightBrace.with(\.leadingTrivia, .space)
        result.accessorBlock = block
        return DeclSyntax(result)
    }

    private func inlineFor(_ node: ForStmtSyntax) -> StmtSyntax {
        guard canInline(node.body) else { return super.visit(node) }

        let startToken = node.forKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText) else {
            return super.visit(node)
        }

        diagnose(.inlineLoopBody, on: node.body.leftBrace)

        var result = node
        result.body = inliningBody(node.body)
        return StmtSyntax(result)
    }

    private func inlineWhile(_ node: WhileStmtSyntax) -> StmtSyntax {
        guard canInline(node.body) else { return super.visit(node) }

        let startToken = node.whileKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText) else {
            return super.visit(node)
        }

        diagnose(.inlineLoopBody, on: node.body.leftBrace)

        var result = node
        result.body = inliningBody(node.body)
        return StmtSyntax(result)
    }

    private func inlineRepeat(_ node: RepeatStmtSyntax) -> StmtSyntax {
        guard canInline(node.body) else { return super.visit(node) }

        let startToken = node.repeatKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace)

        // repeat { body } while condition — suffix includes " while <condition>"
        let whileClause = " while " + node.condition.trimmedDescription
        guard
            fitsInline(
                prefixLength: prefix,
                bodyText: bodyText,
                suffixLength: whileClause.count
            )
        else {
            return super.visit(node)
        }

        diagnose(.inlineLoopBody, on: node.body.leftBrace)

        var result = node
        result.body = inliningBody(node.body)
        // Fix up the while keyword spacing
        result.body.rightBrace = result.body.rightBrace.with(\.trailingTrivia, .space)
        result.whileKeyword = result.whileKeyword.with(\.leadingTrivia, [])
        return StmtSyntax(result)
    }

    private func inlineProperty(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
        guard let accessorBlock = node.accessorBlock else { return node }

        switch accessorBlock.accessors {
        case .getter(let statements):
            guard statements.count == 1 else { return node }
            guard let firstStmt = statements.first,
                firstStmt.leadingTrivia.containsNewlines
            else { return node }

            let bodyText = firstStmt.trimmedDescription
            // For properties, compute from the var keyword
            let varIndent = resolveVarIndent(node)
            // We need the text from line start to `{`
            // Use the var decl's full text up to the accessor block
            if let varDecl = node.parent?.parent?.as(VariableDeclSyntax.self) {
                let prefix = prefixLength(
                    from: varDecl.bindingSpecifier,
                    to: accessorBlock.leftBrace
                )
                guard fitsInline(prefixLength: prefix, bodyText: bodyText) else { return node }
            } else {
                // Fallback: estimate
                let estimate = varIndent.count + node.trimmedDescription.count
                guard estimate <= maxLength else { return node }
            }

            diagnose(.inlinePropertyBody, on: accessorBlock.leftBrace)

            var result = node
            var block = accessorBlock
            block.leftBrace = block.leftBrace.with(\.trailingTrivia, .space)
            var items = Array(statements)
            items[0].leadingTrivia = []
            items[0].trailingTrivia = []
            block.accessors = .getter(CodeBlockItemListSyntax(items))
            block.rightBrace = block.rightBrace.with(\.leadingTrivia, .space)
            result.accessorBlock = block
            return result

        case .accessors:
            // Don't inline explicit accessors (get/set/didSet/willSet) —
            // they're complex enough to stay wrapped
            return node
        }
    }
}

// MARK: - Shared Helpers

extension WrapSingleLineBodies {

    private func resolveIndent(from trivia: Trivia) -> String {
        if trivia.containsNewlines { return trivia.indentation }
        return currentIndent
    }

    private func resolveVarIndent(_ node: PatternBindingSyntax) -> String {
        if let varDecl = node.parent?.parent?.as(VariableDeclSyntax.self) {
            return varDecl.bindingSpecifier.leadingTrivia.indentation
        }
        return ""
    }
}

// MARK: - Finding Messages

extension Finding.Message {
    fileprivate static let wrapConditionalBody: Finding.Message =
        "wrap conditional body onto a new line"

    fileprivate static let wrapFunctionBody: Finding.Message =
        "wrap function body onto a new line"

    fileprivate static let wrapLoopBody: Finding.Message =
        "wrap loop body onto a new line"

    fileprivate static let wrapPropertyBody: Finding.Message =
        "wrap property body onto a new line"

    fileprivate static let inlineConditionalBody: Finding.Message =
        "place conditional body on same line as declaration"

    fileprivate static let inlineFunctionBody: Finding.Message =
        "place function body on same line as declaration"

    fileprivate static let inlineLoopBody: Finding.Message =
        "place loop body on same line as declaration"

    fileprivate static let inlinePropertyBody: Finding.Message =
        "place property body on same line as declaration"
}

// MARK: - Configuration

package struct SingleLineBodiesConfiguration: SyntaxRuleValue {
    package enum Mode: String, Codable, Sendable {
        /// Expand single-line bodies onto multiple lines.
        case wrap
        /// Collapse multi-line single-statement bodies onto one line.
        case inline
    }

    package var rewrite = true
    package var lint: Lint = .warn
    package var mode: Mode = .wrap

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) { self.rewrite = rewrite }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        self.mode =
            try container.decodeIfPresent(Mode.self, forKey: .mode)
            ?? .wrap
    }
}
