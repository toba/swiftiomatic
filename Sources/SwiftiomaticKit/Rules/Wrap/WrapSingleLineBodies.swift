import SwiftSyntax

/// Controls whether single-statement bodies are kept inline or wrapped to multiple lines.
///
/// **Wrap mode** (default): Single-line bodies in conditionals, functions, loops, and properties
/// are expanded onto multiple lines.
///
/// **Inline mode**: Multi-line single-statement bodies are collapsed onto the same line as the
/// declaration, provided the result fits within the configured line length.
///
/// Lint: A body whose formatting doesn't match the mode raises a warning.
///
/// Rewrite: The body is wrapped or inlined to match the mode.
final class WrapSingleLineBodies: RewriteSyntaxRule<SingleLineBodiesConfiguration>,
    @unchecked Sendable
{
    override class var key: String { "singleLineBodies" }
    override class var defaultValue: SingleLineBodiesConfiguration {
        var config = SingleLineBodiesConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }
    override class var group: ConfigurationGroup? { .wrap }

    // MARK: - Conditionals

    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node).cast(IfExprSyntax.self)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: IfExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        switch context.configuration[Self.self].mode {
            case .wrap: wrapIf(node, parent: parent, context: context)
            case .inline: inlineIf(node, context: context)
        }
    }

    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node).cast(GuardStmtSyntax.self)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: GuardStmtSyntax,
        parent: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch context.configuration[Self.self].mode {
            case .wrap: wrapGuard(node, context: context)
            case .inline: inlineGuard(node, context: context)
        }
    }

    // MARK: - Functions

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node).cast(FunctionDeclSyntax.self)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch context.configuration[Self.self].mode {
            case .wrap: wrapFunction(node, context: context)
            case .inline: inlineFunction(node, context: context)
        }
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node).cast(InitializerDeclSyntax.self)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch context.configuration[Self.self].mode {
            case .wrap: wrapInit(node, context: context)
            case .inline: inlineInit(node, context: context)
        }
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node).cast(SubscriptDeclSyntax.self)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch context.configuration[Self.self].mode {
            case .wrap: wrapSubscript(node, context: context)
            case .inline: inlineSubscript(node, context: context)
        }
    }

    // MARK: - Loops

    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node).cast(ForStmtSyntax.self)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: ForStmtSyntax,
        parent: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch context.configuration[Self.self].mode {
            case .wrap: wrapFor(node, context: context)
            case .inline: inlineFor(node, context: context)
        }
    }

    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node).cast(WhileStmtSyntax.self)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: WhileStmtSyntax,
        parent: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch context.configuration[Self.self].mode {
            case .wrap: wrapWhile(node, context: context)
            case .inline: inlineWhile(node, context: context)
        }
    }

    override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node).cast(RepeatStmtSyntax.self)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: RepeatStmtSyntax,
        parent: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch context.configuration[Self.self].mode {
            case .wrap: wrapRepeat(node, context: context)
            case .inline: inlineRepeat(node, context: context)
        }
    }

    // MARK: - Properties

    override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: PatternBindingSyntax,
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        switch context.configuration[Self.self].mode {
            case .wrap: wrapProperty(node, context: context)
            case .inline: inlineProperty(node, context: context)
        }
    }

    // MARK: - Property Observers

    override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node).cast(AccessorDeclSyntax.self)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: AccessorDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        // Only handle willSet/didSet observer bodies in inline mode
        guard context.configuration[Self.self].mode == .inline,
              node.accessorSpecifier.tokenKind == .keyword(.didSet)
                  || node.accessorSpecifier.tokenKind == .keyword(.willSet)
        else { return DeclSyntax(node) }

        return inlineObserver(node, context: context)
    }
}

// MARK: - Wrap Mode

extension WrapSingleLineBodies {
    /// Resolves the base indent for an `if` chain. `parent` is the captured pre-recursion parent
    /// from the static transform.
    private static func wrapIf(
        _ node: IfExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let baseIndent = resolveIndent(from: node.ifKeyword.leadingTrivia)

        let needsBodyWrap = node.body.bodyNeedsWrapping
        if needsBodyWrap {
            Self.diagnose(.wrapConditionalBody, on: node.body.leftBrace, context: context)
        }

        var result = node
        // Children already recursed by the combined rewriter; just wrap the local body.
        if needsBodyWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }

        if let elseBody = node.elseBody {
            switch elseBody {
                case .ifExpr:
                    // Nested if was already visited / transformed by the combined rewriter.
                    break
                case var .codeBlock(block):
                    let needsElseWrap = block.bodyNeedsWrapping
                    if needsElseWrap {
                        Self.diagnose(.wrapConditionalBody, on: block.leftBrace, context: context)
                    }
                    if needsElseWrap { block = block.wrappingBody(baseIndent: baseIndent) }
                    result.elseBody = .codeBlock(block)
            }
        }

        return ExprSyntax(result)
    }

    private static func wrapGuard(_ node: GuardStmtSyntax, context: Context) -> StmtSyntax {
        let baseIndent = resolveIndent(from: node.guardKeyword.leadingTrivia)

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap {
            Self.diagnose(.wrapConditionalBody, on: node.body.leftBrace, context: context)
        }

        var result = node
        if needsWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }
        return StmtSyntax(result)
    }

    private static func wrapFunction(
        _ node: FunctionDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body, body.bodyNeedsWrapping else { return DeclSyntax(node) }

        Self.diagnose(.wrapFunctionBody, on: body.leftBrace, context: context)

        let baseIndent = node.funcKeyword.leadingTrivia.indentation
        var result = node
        result.body = body.wrappingBody(baseIndent: baseIndent)
        return DeclSyntax(result)
    }

    private static func wrapInit(_ node: InitializerDeclSyntax, context: Context) -> DeclSyntax {
        guard let body = node.body, body.bodyNeedsWrapping else { return DeclSyntax(node) }

        Self.diagnose(.wrapFunctionBody, on: body.leftBrace, context: context)

        let baseIndent = node.initKeyword.leadingTrivia.indentation
        var result = node
        result.body = body.wrappingBody(baseIndent: baseIndent)
        return DeclSyntax(result)
    }

    private static func wrapSubscript(
        _ node: SubscriptDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let accessorBlock = node.accessorBlock,
              case let .getter(statements) = accessorBlock.accessors,
              !statements.isEmpty else { return DeclSyntax(node) }

        guard let firstStmt = statements.first,
              !firstStmt.leadingTrivia.containsNewlines else { return DeclSyntax(node) }

        let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
        guard !closingOnNewLine else { return DeclSyntax(node) }

        Self.diagnose(.wrapFunctionBody, on: accessorBlock.leftBrace, context: context)

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

    private static func wrapFor(_ node: ForStmtSyntax, context: Context) -> StmtSyntax {
        let baseIndent = resolveIndent(from: node.forKeyword.leadingTrivia)

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap { Self.diagnose(.wrapLoopBody, on: node.body.leftBrace, context: context) }

        var result = node
        if needsWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }
        return StmtSyntax(result)
    }

    private static func wrapWhile(_ node: WhileStmtSyntax, context: Context) -> StmtSyntax {
        let baseIndent = resolveIndent(from: node.whileKeyword.leadingTrivia)

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap { Self.diagnose(.wrapLoopBody, on: node.body.leftBrace, context: context) }

        var result = node
        if needsWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }
        return StmtSyntax(result)
    }

    private static func wrapRepeat(_ node: RepeatStmtSyntax, context: Context) -> StmtSyntax {
        let baseIndent = resolveIndent(from: node.repeatKeyword.leadingTrivia)

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap { Self.diagnose(.wrapLoopBody, on: node.body.leftBrace, context: context) }

        var result = node
        if needsWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }
        return StmtSyntax(result)
    }

    private static func wrapProperty(
        _ node: PatternBindingSyntax,
        context: Context
    ) -> PatternBindingSyntax {
        guard let accessorBlock = node.accessorBlock else { return node }

        switch accessorBlock.accessors {
            case let .getter(statements):
                guard !statements.isEmpty else { return node }
                guard let firstStmt = statements.first,
                      !firstStmt.leadingTrivia.containsNewlines else { return node }
                let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
                guard !closingOnNewLine else { return node }

                Self.diagnose(.wrapPropertyBody, on: accessorBlock.leftBrace, context: context)

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
                items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia
                    .trimmingTrailingWhitespace
                block.accessors = .getter(CodeBlockItemListSyntax(items))

                block.rightBrace = block.rightBrace.with(
                    \.leadingTrivia,
                    .newline + Trivia(stringLiteral: baseIndent)
                )

                result.accessorBlock = block
                return result

            case let .accessors(accessors):
                guard accessors.contains(where: { $0.body != nil }) else { return node }

                guard let firstAccessor = accessors.first,
                      !firstAccessor.leadingTrivia.containsNewlines
                else { return node }
                let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
                guard !closingOnNewLine else { return node }

                Self.diagnose(.wrapPropertyBody, on: accessorBlock.leftBrace, context: context)

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
                items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia
                    .trimmingTrailingWhitespace
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
    /// Whether a code block is already inline (body and closing brace on same line as opening
    /// brace).
    private static func isAlreadyInline(_ body: CodeBlockSyntax) -> Bool {
        guard let firstStmt = body.statements.first else { return true }
        return !firstStmt.leadingTrivia.containsNewlines
            && !body.rightBrace.leadingTrivia.containsNewlines
    }

    /// Whether a code block has exactly one statement and is wrapped across multiple lines.
    private static func canInline(_ body: CodeBlockSyntax) -> Bool {
        guard body.statements.count == 1 else { return false }
        return !isAlreadyInline(body)
    }

    /// Computes the length of the last line of a declaration prefix, up to and including the left
    /// brace. For multi-line prefixes (e.g. an `if` with comma-separated conditions across several
    /// lines), only the last line counts — that's the line the inlined body will join. If the brace
    /// currently sits on its own line, the result reflects the brace being glued to the previous
    /// token with a single space.
    private static func prefixLength(
        from _: TokenSyntax,
        to leftBrace: TokenSyntax,
        context: Context
    ) -> Int {
        let converter = context.sourceLocationConverter
        if leftBrace.leadingTrivia.containsNewlines,
           let prev = leftBrace.previousToken(viewMode: .sourceAccurate)
        {
            let prevEnd = prev.endLocation(converter: converter)
            return (prevEnd.column - 1) + 2  // " {"
        }
        let braceEnd = leftBrace.endLocation(converter: converter)
        return braceEnd.column - 1
    }

    /// Returns the trimmed body text for a single-statement code block.
    private static func singleStatementText(_ body: CodeBlockSyntax) -> String {
        body.statements.first!.trimmedDescription
    }

    /// Checks if inlining the body would fit within the max line length. The inline form is:
    /// `<prefix> { <body> }<suffix>`
    private static func fitsInline(
        prefixLength: Int,
        bodyText: String,
        suffixLength: Int = 0,
        context: Context
    ) -> Bool {
        // prefixLength already includes the `{` . Inline form adds " " + body + " }".
        let totalLength = prefixLength + 1 + bodyText.count + 2 + suffixLength
        return totalLength <= context.configuration[LineLength.self]
    }

    /// Returns a copy of the code block with the body inlined.
    private static func inliningBody(_ body: CodeBlockSyntax) -> CodeBlockSyntax {
        var result = body
        if result.leftBrace.leadingTrivia.containsNewlines {
            result.leftBrace = result.leftBrace.with(\.leadingTrivia, .space)
        }
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

    private static func inlineIf(_ node: IfExprSyntax, context: Context) -> ExprSyntax {
        // For inline mode, only handle simple single-body if statements (no else chains)
        guard node.elseBody == nil else { return ExprSyntax(node) }
        guard canInline(node.body) else { return ExprSyntax(node) }

        let startToken = node.ifKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace, context: context)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return ExprSyntax(node) }

        Self.diagnose(.inlineConditionalBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = inliningBody(node.body)
        return ExprSyntax(result)
    }

    private static func inlineGuard(_ node: GuardStmtSyntax, context: Context) -> StmtSyntax {
        guard canInline(node.body) else { return StmtSyntax(node) }

        let startToken = node.guardKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace, context: context)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return StmtSyntax(node) }

        Self.diagnose(.inlineConditionalBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = inliningBody(node.body)
        return StmtSyntax(result)
    }

    private static func inlineFunction(
        _ node: FunctionDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body, canInline(body) else { return DeclSyntax(node) }

        let startToken = node.funcKeyword
        let bodyText = singleStatementText(body)
        let prefix = prefixLength(from: startToken, to: body.leftBrace, context: context)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return DeclSyntax(node) }

        Self.diagnose(.inlineFunctionBody, on: body.leftBrace, context: context)

        var result = node
        result.body = inliningBody(body)
        return DeclSyntax(result)
    }

    private static func inlineInit(_ node: InitializerDeclSyntax, context: Context) -> DeclSyntax {
        guard let body = node.body, canInline(body) else { return DeclSyntax(node) }

        let startToken = node.initKeyword
        let bodyText = singleStatementText(body)
        let prefix = prefixLength(from: startToken, to: body.leftBrace, context: context)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return DeclSyntax(node) }

        Self.diagnose(.inlineFunctionBody, on: body.leftBrace, context: context)

        var result = node
        result.body = inliningBody(body)
        return DeclSyntax(result)
    }

    private static func inlineSubscript(
        _ node: SubscriptDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let accessorBlock = node.accessorBlock,
              case let .getter(statements) = accessorBlock.accessors,
              statements.count == 1 else { return DeclSyntax(node) }

        // Must be wrapped (not already inline)
        guard let firstStmt = statements.first,
              firstStmt.leadingTrivia.containsNewlines else { return DeclSyntax(node) }

        let startToken = node.subscriptKeyword
        let bodyText = firstStmt.trimmedDescription
        let prefix = prefixLength(from: startToken, to: accessorBlock.leftBrace, context: context)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return DeclSyntax(node) }

        Self.diagnose(.inlineFunctionBody, on: accessorBlock.leftBrace, context: context)

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

    private static func inlineFor(_ node: ForStmtSyntax, context: Context) -> StmtSyntax {
        guard canInline(node.body) else { return StmtSyntax(node) }

        let startToken = node.forKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace, context: context)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return StmtSyntax(node) }

        Self.diagnose(.inlineLoopBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = inliningBody(node.body)
        return StmtSyntax(result)
    }

    private static func inlineWhile(_ node: WhileStmtSyntax, context: Context) -> StmtSyntax {
        guard canInline(node.body) else { return StmtSyntax(node) }

        let startToken = node.whileKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace, context: context)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return StmtSyntax(node) }

        Self.diagnose(.inlineLoopBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = inliningBody(node.body)
        return StmtSyntax(result)
    }

    private static func inlineRepeat(_ node: RepeatStmtSyntax, context: Context) -> StmtSyntax {
        guard canInline(node.body) else { return StmtSyntax(node) }

        let startToken = node.repeatKeyword
        let bodyText = singleStatementText(node.body)
        let prefix = prefixLength(from: startToken, to: node.body.leftBrace, context: context)

        // repeat { body } while condition — suffix includes " while <condition>"
        let whileClause = " while " + node.condition.trimmedDescription

        guard fitsInline(
            prefixLength: prefix,
            bodyText: bodyText,
            suffixLength: whileClause.count,
            context: context
        ) else { return StmtSyntax(node) }

        Self.diagnose(.inlineLoopBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = inliningBody(node.body)
        // Fix up the while keyword spacing
        result.body.rightBrace = result.body.rightBrace.with(\.trailingTrivia, .space)
        result.whileKeyword = result.whileKeyword.with(\.leadingTrivia, [])
        return StmtSyntax(result)
    }

    private static func inlineProperty(
        _ node: PatternBindingSyntax,
        context: Context
    ) -> PatternBindingSyntax {
        guard let accessorBlock = node.accessorBlock else { return node }

        switch accessorBlock.accessors {
            case let .getter(statements):
                guard statements.count == 1 else { return node }
                guard let firstStmt = statements.first,
                      firstStmt.leadingTrivia.containsNewlines else { return node }

                let bodyText = firstStmt.trimmedDescription
                // For properties, compute from the var keyword
                let varIndent = resolveVarIndent(node)
                // We need the text from line start to `{` Use the var decl's full text up to the
                // accessor block
                if let varDecl = node.parent?.parent?.as(VariableDeclSyntax.self) {
                    let prefix = prefixLength(
                        from: varDecl.bindingSpecifier,
                        to: accessorBlock.leftBrace,
                        context: context
                    )
                    guard fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
                    else { return node }
                } else {
                    // Fallback: estimate
                    let estimate = varIndent.count + node.trimmedDescription.count
                    guard estimate <= context.configuration[LineLength.self] else { return node }
                }

                Self.diagnose(.inlinePropertyBody, on: accessorBlock.leftBrace, context: context)

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

            case .accessors: return node
        }
    }

    private static func inlineObserver(
        _ node: AccessorDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body, canInline(body) else { return DeclSyntax(node) }

        let bodyText = singleStatementText(body)
        let prefix = prefixLength(from: node.accessorSpecifier, to: body.leftBrace, context: context)

        guard fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return DeclSyntax(node) }

        Self.diagnose(.inlineObserverBody, on: body.leftBrace, context: context)

        var result = node
        result.body = inliningBody(body)
        return DeclSyntax(result)
    }
}

// MARK: - Shared Helpers

extension WrapSingleLineBodies {
    /// Returns the indentation derived from the given trivia. Without instance state for the
    /// caller's "current indent", we fall back to an empty string when the trivia contains no
    /// newline — the pretty printer will re-indent later if needed.
    private static func resolveIndent(from trivia: Trivia) -> String {
        if trivia.containsNewlines { return trivia.indentation }
        return ""
    }

    private static func resolveVarIndent(_ node: PatternBindingSyntax) -> String {
        if let varDecl = node.parent?.parent?.as(VariableDeclSyntax.self) {
            return varDecl.bindingSpecifier.leadingTrivia.indentation
        }
        return ""
    }
}

// MARK: - Finding Messages

fileprivate extension Finding.Message {
    static let wrapConditionalBody: Finding.Message = "wrap conditional body onto a new line"

    static let wrapFunctionBody: Finding.Message = "wrap function body onto a new line"

    static let wrapLoopBody: Finding.Message = "wrap loop body onto a new line"

    static let wrapPropertyBody: Finding.Message = "wrap property body onto a new line"

    static let inlineConditionalBody: Finding.Message =
        "place conditional body on same line as declaration"

    static let inlineFunctionBody: Finding.Message =
        "place function body on same line as declaration"

    static let inlineLoopBody: Finding.Message = "place loop body on same line as declaration"

    static let inlinePropertyBody: Finding.Message =
        "place property body on same line as declaration"

    static let inlineObserverBody: Finding.Message = "place observer body on same line as accessor"
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
    /// `wrap` expands single-line bodies onto multiple lines; `inline` collapses multi-line
    /// single-statement bodies onto one line.
    package var mode: Mode = .wrap

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }

        mode = try container.decodeIfPresent(Mode.self, forKey: .mode) ?? .wrap
    }
}
