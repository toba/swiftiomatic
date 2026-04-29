import SwiftSyntax

/// Per-file state for the compact-pipeline `WrapSingleLineBodies` rule. The
/// `indentStack` tracks the baseIndent of each enclosing wrapping construct
/// (`for` / `while` / `repeat` / `guard` / `if`) so a same-line nested
/// construct can derive its own baseIndent when its trivia carries no newline.
final class WrapSingleLineBodiesState {
    var indentStack: [String] = []
}

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
}

// MARK: - Static transform (compact pipeline)

extension WrapSingleLineBodies {
    private static func mode(context: Context) -> SingleLineBodiesConfiguration.Mode {
        context.configuration[Self.self].mode
    }

    private static func maxLength(context: Context) -> Int {
        context.configuration[LineLength.self]
    }

    static func transform(
        _ node: IfExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapIf(node, parent: parent, context: context)
            case .inline: Self.inlineIf(node, context: context)
        }
    }

    static func transform(
        _ node: GuardStmtSyntax,
        parent: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapGuard(node, context: context)
            case .inline: Self.inlineGuard(node, context: context)
        }
    }

    static func transform(
        _ node: FunctionDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapFunction(node, context: context)
            case .inline: Self.inlineFunction(node, context: context)
        }
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapInit(node, context: context)
            case .inline: Self.inlineInit(node, context: context)
        }
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapSubscript(node, context: context)
            case .inline: Self.inlineSubscript(node, context: context)
        }
    }

    static func transform(
        _ node: ForStmtSyntax,
        parent: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapFor(node, context: context)
            case .inline: Self.inlineFor(node, context: context)
        }
    }

    static func transform(
        _ node: WhileStmtSyntax,
        parent: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapWhile(node, context: context)
            case .inline: Self.inlineWhile(node, context: context)
        }
    }

    static func transform(
        _ node: RepeatStmtSyntax,
        parent: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapRepeat(node, context: context)
            case .inline: Self.inlineRepeat(node, context: context)
        }
    }

    static func transform(
        _ node: PatternBindingSyntax,
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapProperty(node, parent: parent, context: context)
            case .inline: Self.inlineProperty(node, parent: parent, context: context)
        }
    }

    static func transform(
        _ node: AccessorDeclSyntax,
        parent: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard Self.mode(context: context) == .inline,
              node.accessorSpecifier.tokenKind == .keyword(.didSet)
                  || node.accessorSpecifier.tokenKind == .keyword(.willSet)
        else { return DeclSyntax(node) }

        return Self.inlineObserver(node, context: context)
    }

    // MARK: Wrap helpers (static)

    /// Mirrors the legacy `currentIndent`/`chainBaseIndent` instance state via
    /// `Context.ruleState`. The compact pipeline runs post-order, so a `for` /
    /// `while` / `repeat` / `guard` / `if` whose keyword sits on the same line as
    /// its enclosing `{` cannot derive its baseIndent from trivia. The static
    /// `willEnter` hooks push each construct's baseIndent onto `indentStack`
    /// before children are visited; `didExit` pops it. The wrap helpers read
    /// `indentStack.last` rather than recomputing from trivia.
    fileprivate static func state(_ context: Context) -> WrapSingleLineBodiesState {
        context.ruleState(for: WrapSingleLineBodies.self) { WrapSingleLineBodiesState() }
    }

    /// Computes a wrapping construct's baseIndent. Trivia wins when it contains
    /// a newline; otherwise we synthesize from the enclosing construct's own
    /// baseIndent (one level deeper). For else-if chains the inner `if` reuses
    /// the outer `if`'s baseIndent (matches legacy `chainBaseIndent`).
    fileprivate static func computeBaseIndent(
        trivia: Trivia,
        isElseIf: Bool,
        state: WrapSingleLineBodiesState
    ) -> String {
        if isElseIf, let outer = state.indentStack.last { return outer }
        if trivia.containsNewlines { return trivia.indentation }
        if let outer = state.indentStack.last { return outer + "    " }
        return ""
    }

    fileprivate static func resolveIndent(from trivia: Trivia) -> String {
        if trivia.containsNewlines { return trivia.indentation }
        return ""
    }

    fileprivate static func resolveVarIndent(
        _ node: PatternBindingSyntax,
        parent: Syntax?
    ) -> String {
        if let varDecl = parent?.parent?.as(VariableDeclSyntax.self) {
            return varDecl.bindingSpecifier.leadingTrivia.indentation
        }
        return ""
    }

    fileprivate static func wrapIf(
        _ node: IfExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // willEnter has already pushed self's baseIndent onto the stack.
        let baseIndent = Self.state(context).indentStack.last ?? ""
        _ = parent

        let needsBodyWrap = node.body.bodyNeedsWrapping
        if needsBodyWrap {
            Self.diagnose(.wrapConditionalBody, on: node.body.leftBrace, context: context)
        }

        var result = node
        if needsBodyWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }

        if let elseBody = node.elseBody {
            switch elseBody {
                case .ifExpr: break
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

    fileprivate static func wrapGuard(
        _ node: GuardStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        let baseIndent = Self.state(context).indentStack.last ?? ""

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap {
            Self.diagnose(.wrapConditionalBody, on: node.body.leftBrace, context: context)
        }

        var result = node
        if needsWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }
        return StmtSyntax(result)
    }

    fileprivate static func wrapFunction(
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

    fileprivate static func wrapInit(
        _ node: InitializerDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body, body.bodyNeedsWrapping else { return DeclSyntax(node) }

        Self.diagnose(.wrapFunctionBody, on: body.leftBrace, context: context)

        let baseIndent = node.initKeyword.leadingTrivia.indentation
        var result = node
        result.body = body.wrappingBody(baseIndent: baseIndent)
        return DeclSyntax(result)
    }

    fileprivate static func wrapSubscript(
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

    fileprivate static func wrapFor(
        _ node: ForStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        let baseIndent = Self.state(context).indentStack.last ?? ""

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap { Self.diagnose(.wrapLoopBody, on: node.body.leftBrace, context: context) }

        var result = node
        if needsWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }
        return StmtSyntax(result)
    }

    fileprivate static func wrapWhile(
        _ node: WhileStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        let baseIndent = Self.state(context).indentStack.last ?? ""

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap { Self.diagnose(.wrapLoopBody, on: node.body.leftBrace, context: context) }

        var result = node
        if needsWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }
        return StmtSyntax(result)
    }

    fileprivate static func wrapRepeat(
        _ node: RepeatStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        let baseIndent = Self.state(context).indentStack.last ?? ""

        let needsWrap = node.body.bodyNeedsWrapping
        if needsWrap { Self.diagnose(.wrapLoopBody, on: node.body.leftBrace, context: context) }

        var result = node
        if needsWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }
        return StmtSyntax(result)
    }

    fileprivate static func wrapProperty(
        _ node: PatternBindingSyntax,
        parent: Syntax?,
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

                let baseIndent = Self.resolveVarIndent(node, parent: parent)
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

                let baseIndent = Self.resolveVarIndent(node, parent: parent)
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

    // MARK: Inline helpers (static)

    fileprivate static func isAlreadyInline(_ body: CodeBlockSyntax) -> Bool {
        guard let firstStmt = body.statements.first else { return true }
        return !firstStmt.leadingTrivia.containsNewlines
            && !body.rightBrace.leadingTrivia.containsNewlines
    }

    fileprivate static func canInline(_ body: CodeBlockSyntax) -> Bool {
        guard body.statements.count == 1 else { return false }
        return !Self.isAlreadyInline(body)
    }

    fileprivate static func prefixLength(
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

    fileprivate static func singleStatementText(_ body: CodeBlockSyntax) -> String {
        body.statements.first!.trimmedDescription
    }

    fileprivate static func fitsInline(
        prefixLength: Int,
        bodyText: String,
        suffixLength: Int = 0,
        context: Context
    ) -> Bool {
        let totalLength = prefixLength + 1 + bodyText.count + 2 + suffixLength
        return totalLength <= Self.maxLength(context: context)
    }

    fileprivate static func inliningBody(_ body: CodeBlockSyntax) -> CodeBlockSyntax {
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

    fileprivate static func inlineIf(
        _ node: IfExprSyntax,
        context: Context
    ) -> ExprSyntax {
        guard node.elseBody == nil else { return ExprSyntax(node) }
        guard Self.canInline(node.body) else { return ExprSyntax(node) }

        let bodyText = Self.singleStatementText(node.body)
        let prefix = Self.prefixLength(
            from: node.ifKeyword,
            to: node.body.leftBrace,
            context: context
        )

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return ExprSyntax(node) }

        Self.diagnose(.inlineConditionalBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = Self.inliningBody(node.body)
        return ExprSyntax(result)
    }

    fileprivate static func inlineGuard(
        _ node: GuardStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        guard Self.canInline(node.body) else { return StmtSyntax(node) }

        let bodyText = Self.singleStatementText(node.body)
        let prefix = Self.prefixLength(
            from: node.guardKeyword,
            to: node.body.leftBrace,
            context: context
        )

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return StmtSyntax(node) }

        Self.diagnose(.inlineConditionalBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = Self.inliningBody(node.body)
        return StmtSyntax(result)
    }

    fileprivate static func inlineFunction(
        _ node: FunctionDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body, Self.canInline(body) else { return DeclSyntax(node) }

        let bodyText = Self.singleStatementText(body)
        let prefix = Self.prefixLength(
            from: node.funcKeyword,
            to: body.leftBrace,
            context: context
        )

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return DeclSyntax(node) }

        Self.diagnose(.inlineFunctionBody, on: body.leftBrace, context: context)

        var result = node
        result.body = Self.inliningBody(body)
        return DeclSyntax(result)
    }

    fileprivate static func inlineInit(
        _ node: InitializerDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body, Self.canInline(body) else { return DeclSyntax(node) }

        let bodyText = Self.singleStatementText(body)
        let prefix = Self.prefixLength(
            from: node.initKeyword,
            to: body.leftBrace,
            context: context
        )

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return DeclSyntax(node) }

        Self.diagnose(.inlineFunctionBody, on: body.leftBrace, context: context)

        var result = node
        result.body = Self.inliningBody(body)
        return DeclSyntax(result)
    }

    fileprivate static func inlineSubscript(
        _ node: SubscriptDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let accessorBlock = node.accessorBlock,
              case let .getter(statements) = accessorBlock.accessors,
              statements.count == 1 else { return DeclSyntax(node) }

        guard let firstStmt = statements.first,
              firstStmt.leadingTrivia.containsNewlines else { return DeclSyntax(node) }

        let bodyText = firstStmt.trimmedDescription
        let prefix = Self.prefixLength(
            from: node.subscriptKeyword,
            to: accessorBlock.leftBrace,
            context: context
        )

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
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

    fileprivate static func inlineFor(
        _ node: ForStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        guard Self.canInline(node.body) else { return StmtSyntax(node) }

        let bodyText = Self.singleStatementText(node.body)
        let prefix = Self.prefixLength(
            from: node.forKeyword,
            to: node.body.leftBrace,
            context: context
        )

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return StmtSyntax(node) }

        Self.diagnose(.inlineLoopBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = Self.inliningBody(node.body)
        return StmtSyntax(result)
    }

    fileprivate static func inlineWhile(
        _ node: WhileStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        guard Self.canInline(node.body) else { return StmtSyntax(node) }

        let bodyText = Self.singleStatementText(node.body)
        let prefix = Self.prefixLength(
            from: node.whileKeyword,
            to: node.body.leftBrace,
            context: context
        )

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return StmtSyntax(node) }

        Self.diagnose(.inlineLoopBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = Self.inliningBody(node.body)
        return StmtSyntax(result)
    }

    fileprivate static func inlineRepeat(
        _ node: RepeatStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        guard Self.canInline(node.body) else { return StmtSyntax(node) }

        let bodyText = Self.singleStatementText(node.body)
        let prefix = Self.prefixLength(
            from: node.repeatKeyword,
            to: node.body.leftBrace,
            context: context
        )

        let whileClause = " while " + node.condition.trimmedDescription

        guard Self.fitsInline(
            prefixLength: prefix,
            bodyText: bodyText,
            suffixLength: whileClause.count,
            context: context
        ) else { return StmtSyntax(node) }

        Self.diagnose(.inlineLoopBody, on: node.body.leftBrace, context: context)

        var result = node
        result.body = Self.inliningBody(node.body)
        result.body.rightBrace = result.body.rightBrace.with(\.trailingTrivia, .space)
        result.whileKeyword = result.whileKeyword.with(\.leadingTrivia, [])
        return StmtSyntax(result)
    }

    fileprivate static func inlineProperty(
        _ node: PatternBindingSyntax,
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        guard let accessorBlock = node.accessorBlock else { return node }

        switch accessorBlock.accessors {
            case let .getter(statements):
                guard statements.count == 1 else { return node }
                guard let firstStmt = statements.first,
                      firstStmt.leadingTrivia.containsNewlines else { return node }

                let bodyText = firstStmt.trimmedDescription
                let varIndent = Self.resolveVarIndent(node, parent: parent)
                if let varDecl = parent?.parent?.as(VariableDeclSyntax.self) {
                    let prefix = Self.prefixLength(
                        from: varDecl.bindingSpecifier,
                        to: accessorBlock.leftBrace,
                        context: context
                    )
                    guard Self.fitsInline(
                        prefixLength: prefix,
                        bodyText: bodyText,
                        context: context
                    ) else { return node }
                } else {
                    let estimate = varIndent.count + node.trimmedDescription.count
                    guard estimate <= Self.maxLength(context: context) else { return node }
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

    fileprivate static func inlineObserver(
        _ node: AccessorDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let body = node.body, Self.canInline(body) else { return DeclSyntax(node) }

        let bodyText = Self.singleStatementText(body)
        let prefix = Self.prefixLength(
            from: node.accessorSpecifier,
            to: body.leftBrace,
            context: context
        )

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context)
        else { return DeclSyntax(node) }

        Self.diagnose(.inlineObserverBody, on: body.leftBrace, context: context)

        var result = node
        result.body = Self.inliningBody(body)
        return DeclSyntax(result)
    }
}

// MARK: - Compact-pipeline scope hooks

extension WrapSingleLineBodies {
    static func willEnter(_ node: IfExprSyntax, context: Context) {
        let isElseIf = Syntax(node).parent?.is(IfExprSyntax.self) == true
        let state = Self.state(context)
        state.indentStack.append(
            Self.computeBaseIndent(
                trivia: node.ifKeyword.leadingTrivia,
                isElseIf: isElseIf,
                state: state
            )
        )
    }

    static func didExit(_: IfExprSyntax, context: Context) {
        Self.state(context).indentStack.popLast()
    }

    static func willEnter(_ node: GuardStmtSyntax, context: Context) {
        let state = Self.state(context)
        state.indentStack.append(
            Self.computeBaseIndent(
                trivia: node.guardKeyword.leadingTrivia,
                isElseIf: false,
                state: state
            )
        )
    }

    static func didExit(_: GuardStmtSyntax, context: Context) {
        Self.state(context).indentStack.popLast()
    }

    static func willEnter(_ node: ForStmtSyntax, context: Context) {
        let state = Self.state(context)
        state.indentStack.append(
            Self.computeBaseIndent(
                trivia: node.forKeyword.leadingTrivia,
                isElseIf: false,
                state: state
            )
        )
    }

    static func didExit(_: ForStmtSyntax, context: Context) {
        Self.state(context).indentStack.popLast()
    }

    static func willEnter(_ node: WhileStmtSyntax, context: Context) {
        let state = Self.state(context)
        state.indentStack.append(
            Self.computeBaseIndent(
                trivia: node.whileKeyword.leadingTrivia,
                isElseIf: false,
                state: state
            )
        )
    }

    static func didExit(_: WhileStmtSyntax, context: Context) {
        Self.state(context).indentStack.popLast()
    }

    static func willEnter(_ node: RepeatStmtSyntax, context: Context) {
        let state = Self.state(context)
        state.indentStack.append(
            Self.computeBaseIndent(
                trivia: node.repeatKeyword.leadingTrivia,
                isElseIf: false,
                state: state
            )
        )
    }

    static func didExit(_: RepeatStmtSyntax, context: Context) {
        Self.state(context).indentStack.popLast()
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
