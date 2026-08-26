import SwiftSyntax

/// Per-file state for `LayoutSingleLineBodies`. The `indentStack` tracks the baseIndent of each
/// enclosing wrapping construct ( `for` / `while` / `repeat` / `guard` / `if` ) so a same-line
/// nested construct can derive its own baseIndent when its trivia carries no newline.
final class LayoutSingleLineBodiesState {
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
final class LayoutSingleLineBodies: StaticFormatRule<LayoutSingleLineBodiesConfiguration>,
    @unchecked Sendable
{
    override class var defaultValue: LayoutSingleLineBodiesConfiguration {
        var config = LayoutSingleLineBodiesConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }
    override class var group: ConfigurationGroup? { .wrap }
}

// MARK: - Static transform

extension LayoutSingleLineBodies {
    private static func mode(context: Context) -> LayoutSingleLineBodiesConfiguration.Mode {
        context.configuration[Self.self].mode
    }

    private static func maxLength(context: Context) -> Int {
        context.configuration[LineLength.self]
    }

    static func transform(
        _ node: IfExprSyntax,
        original _: IfExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapIf(node, context: context)
            case .inline: Self.inlineIf(node, context: context)
        }
    }

    static func transform(
        _ node: GuardStmtSyntax,
        original _: GuardStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapGuard(node, context: context)
            case .inline: Self.inlineGuard(node, context: context)
        }
    }

    static func transform(
        _ node: FunctionDeclSyntax,
        original _: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapFunction(node, context: context)
            case .inline: Self.inlineFunction(node, context: context)
        }
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        original _: InitializerDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapInit(node, context: context)
            case .inline: Self.inlineInit(node, context: context)
        }
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        original _: SubscriptDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapSubscript(node, context: context)
            case .inline: Self.inlineSubscript(node, context: context)
        }
    }

    static func transform(
        _ node: ForStmtSyntax,
        original _: ForStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapFor(node, context: context)
            case .inline: Self.inlineFor(node, context: context)
        }
    }

    static func transform(
        _ node: WhileStmtSyntax,
        original _: WhileStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapWhile(node, context: context)
            case .inline: Self.inlineWhile(node, context: context)
        }
    }

    static func transform(
        _ node: RepeatStmtSyntax,
        original _: RepeatStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapRepeat(node, context: context)
            case .inline: Self.inlineRepeat(node, context: context)
        }
    }

    static func transform(
        _ node: PatternBindingSyntax,
        original _: PatternBindingSyntax,
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapProperty(node, parent: parent, context: context)
            case .inline: Self.inlineProperty(node, parent: parent, context: context)
        }
    }

    static func transform(
        _ node: ArrayExprSyntax,
        original _: ArrayExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard Self.mode(context: context) == .inline else { return ExprSyntax(node) }
        return Self.inlineArrayLiteral(node, context: context)
    }

    static func transform(
        _ node: DictionaryExprSyntax,
        original _: DictionaryExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard Self.mode(context: context) == .inline else { return ExprSyntax(node) }
        return Self.inlineDictionaryLiteral(node, context: context)
    }

    static func transform(
        _ node: ClosureExprSyntax,
        original: ClosureExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard Self.mode(context: context) == .inline else { return ExprSyntax(node) }
        return Self.inlineClosure(node, original: original, context: context)
    }

    static func transform(
        _ node: AccessorDeclSyntax,
        original _: AccessorDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard Self.mode(context: context) == .inline,
              node.accessorSpecifier.tokenKind == .keyword(.didSet)
                  || node.accessorSpecifier.tokenKind == .keyword(.willSet)
        else {
            return DeclSyntax(node)
        }

        return Self.inlineObserver(node, context: context)
    }

    // MARK: Wrap helpers (static)

    /// The rewriter runs post-order, so a `for` / `while` / `repeat` / `guard` / `if` whose keyword
    /// sits on the same line as its enclosing `{` cannot derive its baseIndent from trivia. The
    /// static `willEnter` hooks push each construct's baseIndent onto `indentStack` before children
    /// are visited; `didExit` pops it. The wrap helpers read `indentStack.last` rather than
    /// recomputing from trivia.
    fileprivate static func state(_ context: Context) -> LayoutSingleLineBodiesState {
        context.layoutSingleLineBodiesState
    }

    /// Computes a wrapping construct's baseIndent. Trivia wins when it contains a newline;
    /// otherwise we synthesize from the enclosing construct's own baseIndent (one level deeper).
    /// For else-if chains the inner `if` reuses the outer `if` 's baseIndent (matches legacy
    /// `chainBaseIndent` ).
    fileprivate static func computeBaseIndent(
        trivia: Trivia,
        isElseIf: Bool,
        state: LayoutSingleLineBodiesState
    ) -> String {
        if isElseIf, let outer = state.indentStack.last { return outer }
        if trivia.containsNewlines { return trivia.indentation }
        if let outer = state.indentStack.last { return outer + "    " }
        return ""
    }

    fileprivate static func resolveVarIndent(parent: Syntax?) -> String {
        if let varDecl = parent?.parent?.as(VariableDeclSyntax.self) {
            return varDecl.bindingSpecifier.leadingTrivia.indentation
        }
        return ""
    }

    fileprivate static func wrapIf(
        _ node: IfExprSyntax,
        context: Context
    ) -> ExprSyntax {
        // willEnter has already pushed self's baseIndent onto the stack.
        let baseIndent = Self.state(context).indentStack.last ?? ""

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

    /// Wraps a statement's body onto its own lines, indented from the enclosing construct
    ///
    /// The construct's baseIndent comes off `indentStack` , which `willEnter` filled before the
    /// children were visited.
    ///
    /// - Parameters:
    ///   - node: the statement that owns the body
    ///   - body: the path to the body to wrap
    ///   - message: the finding the rewrite emits
    /// - Returns: the node with a wrapped body, or the node unchanged when the body already wraps
    fileprivate static func wrappingStatement<Node: SyntaxProtocol>(
        _ node: Node,
        body: WritableKeyPath<Node, CodeBlockSyntax>,
        message: Finding.Message,
        context: Context
    ) -> Node {
        guard node[keyPath: body].bodyNeedsWrapping else { return node }

        Self.diagnose(message, on: node[keyPath: body].leftBrace, context: context)

        let baseIndent = Self.state(context).indentStack.last ?? ""
        var result = node
        result[keyPath: body] = node[keyPath: body].wrappingBody(baseIndent: baseIndent)
        return result
    }

    /// Wraps a declaration's body onto its own lines, indented from its introducer keyword
    ///
    /// - Parameters:
    ///   - node: the declaration that owns the body
    ///   - body: the path to the body to wrap
    ///   - keyword: the path to the keyword whose own indentation the body indents from
    /// - Returns: the node with a wrapped body, or the node unchanged when the body already wraps
    fileprivate static func wrappingDeclaration<Node: SyntaxProtocol>(
        _ node: Node,
        body: WritableKeyPath<Node, CodeBlockSyntax?>,
        keyword: KeyPath<Node, TokenSyntax>,
        context: Context
    ) -> Node {
        guard let block = node[keyPath: body], block.bodyNeedsWrapping else { return node }

        Self.diagnose(.wrapFunctionBody, on: block.leftBrace, context: context)

        let baseIndent = node[keyPath: keyword].leadingTrivia.indentation
        var result = node
        result[keyPath: body] = block.wrappingBody(baseIndent: baseIndent)
        return result
    }

    fileprivate static func wrapGuard(
        _ node: GuardStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        StmtSyntax(Self.wrappingStatement(
            node, body: \.body, message: .wrapConditionalBody, context: context))
    }

    fileprivate static func wrapFunction(
        _ node: FunctionDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(Self.wrappingDeclaration(
            node, body: \.body, keyword: \.funcKeyword, context: context))
    }

    fileprivate static func wrapInit(
        _ node: InitializerDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(Self.wrappingDeclaration(
            node, body: \.body, keyword: \.initKeyword, context: context))
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
        StmtSyntax(Self.wrappingStatement(
            node, body: \.body, message: .wrapLoopBody, context: context))
    }

    fileprivate static func wrapWhile(
        _ node: WhileStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        StmtSyntax(Self.wrappingStatement(
            node, body: \.body, message: .wrapLoopBody, context: context))
    }

    fileprivate static func wrapRepeat(
        _ node: RepeatStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        StmtSyntax(Self.wrappingStatement(
            node, body: \.body, message: .wrapLoopBody, context: context))
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

                let baseIndent = Self.resolveVarIndent(parent: parent)
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
                      !firstAccessor.leadingTrivia.containsNewlines else { return node }
                let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
                guard !closingOnNewLine else { return node }

                Self.diagnose(.wrapPropertyBody, on: accessorBlock.leftBrace, context: context)

                let baseIndent = Self.resolveVarIndent(parent: parent)
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
        if Self.bodyHasComments(body) { return false }
        return Self.commentPrecedesBrace(body.leftBrace) ? false : !Self.isAlreadyInline(body)
    }

    /// Whether a comment sits between the preceding code and an opening brace on a later line
    ///
    /// A line comment runs to the end of its line, so pulling the brace up appends the whole body
    /// after the comment marker and the body becomes comment text. A comment in the brace's own
    /// leading trivia is dropped outright by the same move. Both are silent losses, so an elective
    /// inline is refused whenever either shape appears.
    ///
    /// - Parameters:
    ///   - leftBrace: the opening brace the inline rewrite would move
    ///   - source: the same brace in the tree the file was parsed into. Pass it when the brace is
    ///     the first token of the node under transform, because the comment then sits outside the
    ///     node and the rewritten copy has no parent to reach it through.
    fileprivate static func commentPrecedesBrace(
        _ leftBrace: TokenSyntax,
        source: TokenSyntax? = nil
    ) -> Bool {
        guard leftBrace.leadingTrivia.containsNewlines else { return false }
        if leftBrace.leadingTrivia.hasAnyComments { return true }
        let preceding = leftBrace.previousToken(viewMode: .sourceAccurate)
            ?? source?.previousToken(viewMode: .sourceAccurate)
        return preceding?.trailingTrivia.hasAnyComments ?? false
    }

    /// Comments anywhere inside the body disqualify inlining — collapsing onto one line would drop
    /// them. Leaving the body multiline preserves the comment in place.
    fileprivate static func bodyHasComments(_ body: CodeBlockSyntax) -> Bool {
        if body.leftBrace.trailingTrivia.hasAnyComments { return true }
        if let first = body.statements.first {
            if first.leadingTrivia.hasAnyComments { return true }
        }
        if let last = body.statements.last { if last.trailingTrivia.hasAnyComments { return true } }
        return body.rightBrace.leadingTrivia.hasAnyComments
    }

    /// Whether a comment anywhere around the accessor block refuses the inline
    ///
    /// The question covers three regions, because the inline moves trivia in all three. A comment
    /// before the opening brace buries the body in a comment line. A comment inside the block is
    /// dropped when the block collapses. A comment the statement carries in either direction is
    /// dropped the same way.
    ///
    /// - Parameters:
    ///   - block: the accessor block the inline would collapse
    ///   - statementLeading: the leading trivia of the block's single statement
    ///   - statementTrailing: the trailing trivia of the same statement
    fileprivate static func accessorBlockBlocksInlining(
        _ block: AccessorBlockSyntax,
        statementLeading: Trivia,
        statementTrailing: Trivia
    ) -> Bool {
        if Self.commentPrecedesBrace(block.leftBrace) { return true }
        if block.leftBrace.trailingTrivia.hasAnyComments { return true }
        if statementLeading.hasAnyComments { return true }
        return statementTrailing.hasAnyComments
            ? true : block.rightBrace.leadingTrivia.hasAnyComments
    }

    fileprivate static func prefixLength(
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

    /// The inlined form of a single-statement body, or nil when the inline is refused
    ///
    /// Every construct the inline path rewrites routes its body through here, so `canInline` is the
    /// one place a new comment guard has to land.
    ///
    /// - Parameters:
    ///   - body: the body to collapse. Nil for a declaration that declares none, which refuses.
    ///   - message: the finding the rewrite emits
    ///   - suffixLength: characters that follow the closing brace, as `repeat` 's while clause has
    fileprivate static func inlinedBody(
        _ body: CodeBlockSyntax?,
        message: Finding.Message,
        suffixLength: Int = 0,
        context: Context
    ) -> CodeBlockSyntax? {
        guard let body, Self.canInline(body) else { return nil }

        let prefix = Self.prefixLength(to: body.leftBrace, context: context)
        guard Self.fitsInline(
            prefixLength: prefix,
            bodyText: Self.singleStatementText(body),
            suffixLength: suffixLength,
            context: context
        ) else { return nil }

        Self.diagnose(message, on: body.leftBrace, context: context)
        return Self.inliningBody(body)
    }

    fileprivate static func inlineIf(
        _ node: IfExprSyntax,
        context: Context
    ) -> ExprSyntax {
        guard node.elseBody == nil,
              let body = Self.inlinedBody(
                  node.body,
                  message: .inlineConditionalBody,
                  context: context
              ) else { return ExprSyntax(node) }

        var result = node
        result.body = body
        return ExprSyntax(result)
    }

    fileprivate static func inlineGuard(
        _ node: GuardStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        guard let body = Self.inlinedBody(
            node.body,
            message: .inlineConditionalBody,
            context: context
        ) else { return StmtSyntax(node) }

        var result = node
        result.body = body
        return StmtSyntax(result)
    }

    /// A generic `where` clause wrapped onto its own line (its `where` keyword preceded by a
    /// newline) forces the opening brace onto a separate line. Keeping an inline `{ body }` glued
    /// to that lone brace reads poorly, so the body is wrapped onto new lines instead — even in
    /// inline mode.
    fileprivate static func hasWrappedGenericWhereClause(
        _ clause: GenericWhereClauseSyntax?
    ) -> Bool {
        guard let clause else { return false }
        return clause.whereKeyword.leadingTrivia.containsNewlines
    }

    fileprivate static func inlineFunction(
        _ node: FunctionDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        if Self.hasWrappedGenericWhereClause(node.genericWhereClause) {
            return Self.wrapFunction(node, context: context)
        }
        guard let body = Self.inlinedBody(node.body, message: .inlineFunctionBody, context: context)
        else { return DeclSyntax(node) }

        var result = node
        result.body = body
        return DeclSyntax(result)
    }

    fileprivate static func inlineInit(
        _ node: InitializerDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        if Self.hasWrappedGenericWhereClause(node.genericWhereClause) {
            return Self.wrapInit(node, context: context)
        }
        guard let body = Self.inlinedBody(node.body, message: .inlineFunctionBody, context: context)
        else { return DeclSyntax(node) }

        var result = node
        result.body = body
        return DeclSyntax(result)
    }

    fileprivate static func inlineSubscript(
        _ node: SubscriptDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        if Self.hasWrappedGenericWhereClause(node.genericWhereClause) {
            return Self.wrapSubscript(node, context: context)
        }
        guard let accessorBlock = node.accessorBlock,
              case let .getter(statements) = accessorBlock.accessors,
              statements.count == 1 else { return DeclSyntax(node) }

        guard let firstStmt = statements.first,
              firstStmt.leadingTrivia.containsNewlines else { return DeclSyntax(node) }

        if Self.accessorBlockBlocksInlining(
            accessorBlock,
            statementLeading: firstStmt.leadingTrivia,
            statementTrailing: firstStmt.trailingTrivia
        ) { return DeclSyntax(node) }

        let bodyText = firstStmt.trimmedDescription
        let prefix = Self.prefixLength(to: accessorBlock.leftBrace, context: context)

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context) else {
            return DeclSyntax(node)
        }

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
        guard let body = Self.inlinedBody(node.body, message: .inlineLoopBody, context: context)
        else { return StmtSyntax(node) }

        var result = node
        result.body = body
        return StmtSyntax(result)
    }

    fileprivate static func inlineWhile(
        _ node: WhileStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        guard let body = Self.inlinedBody(node.body, message: .inlineLoopBody, context: context)
        else { return StmtSyntax(node) }

        var result = node
        result.body = body
        return StmtSyntax(result)
    }

    fileprivate static func inlineRepeat(
        _ node: RepeatStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        // The inline glues the while keyword to the closing brace, which drops any comment between
        // the two. Neither canInline nor bodyHasComments reaches that trivia, because both stop at
        // the closing brace.
        guard !node.whileKeyword.leadingTrivia.hasAnyComments,
              !node.body.rightBrace.trailingTrivia.hasAnyComments else { return StmtSyntax(node) }

        let whileClause = " while " + node.condition.trimmedDescription
        guard let body = Self.inlinedBody(
            node.body,
            message: .inlineLoopBody,
            suffixLength: whileClause.count,
            context: context
        ) else { return StmtSyntax(node) }

        var result = node
        result.body = body
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

                if Self.accessorBlockBlocksInlining(
                    accessorBlock,
                    statementLeading: firstStmt.leadingTrivia,
                    statementTrailing: firstStmt.trailingTrivia
                ) { return node }

                let bodyText = firstStmt.trimmedDescription
                let varIndent = Self.resolveVarIndent(parent: parent)

                if parent?.parent?.is(VariableDeclSyntax.self) == true {
                    let prefix = Self.prefixLength(to: accessorBlock.leftBrace, context: context)
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

            case let .accessors(accessors):
                return Self.inlineAccessors(
                    node,
                    block: accessorBlock,
                    accessors: Array(accessors),
                    parent: parent,
                    context: context
                )
        }
    }

    fileprivate static func inlineAccessors(
        _ node: PatternBindingSyntax,
        block accessorBlock: AccessorBlockSyntax,
        accessors: [AccessorDeclSyntax],
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        guard !accessors.isEmpty else { return node }

        for acc in accessors {
            switch acc.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet): return node
                default: break
            }
        }

        let isMultiline = accessors.contains { $0.leadingTrivia.containsNewlines }
            || accessorBlock.rightBrace.leadingTrivia.containsNewlines
        guard isMultiline else { return node }

        if Self.commentPrecedesBrace(accessorBlock.leftBrace) { return node }
        if accessorBlock.leftBrace.trailingTrivia.hasAnyComments { return node }
        if accessorBlock.rightBrace.leadingTrivia.hasAnyComments { return node }

        for acc in accessors {
            guard let body = acc.body else { return node }
            guard body.statements.count == 1 else { return node }
            if Self.bodyHasComments(body) { return node }
            if acc.leadingTrivia.hasAnyComments { return node }
            if acc.trailingTrivia.hasAnyComments { return node }
        }

        let accessorTexts: [String] = accessors.map { acc in
            var text = acc.accessorSpecifier.text
            if let params = acc.parameters { text += params.trimmedDescription }
            if let effects = acc.effectSpecifiers { text += " " + effects.trimmedDescription }
            let bodyText = acc.body!.statements.first!.trimmedDescription
            text += " { \(bodyText) }"
            return text
        }
        let joined = accessorTexts.joined(separator: " ")

        if parent?.parent?.is(VariableDeclSyntax.self) == true {
            let prefix = Self.prefixLength(to: accessorBlock.leftBrace, context: context)
            let total = prefix + 1 + joined.count + 2
            guard total <= Self.maxLength(context: context) else { return node }
        } else {
            let varIndent = Self.resolveVarIndent(parent: parent)
            let estimate = varIndent.count + node.trimmedDescription.count
            guard estimate <= Self.maxLength(context: context) else { return node }
        }

        Self.diagnose(.inlinePropertyBody, on: accessorBlock.leftBrace, context: context)

        var result = node
        var block = accessorBlock
        block.leftBrace = block.leftBrace.with(\.trailingTrivia, .space)

        var newAccessors = accessors
        let lastIdx = newAccessors.count - 1

        for i in newAccessors.indices {
            var acc = newAccessors[i]
            acc.leadingTrivia = []
            if let body = acc.body { acc.body = Self.inliningBody(body) }
            acc.trailingTrivia = (i == lastIdx) ? [] : .space
            newAccessors[i] = acc
        }
        block.accessors = .accessors(AccessorDeclListSyntax(newAccessors))
        block.rightBrace = block.rightBrace.with(\.leadingTrivia, .space)
        result.accessorBlock = block
        return result
    }

    /// Whether a wrapped collection literal is multiline, comment-free, and short enough to inline
    ///
    /// The caller emits the finding and performs the element-specific trivia reset. Both literal
    /// kinds route through here, so one comment guard covers both.
    fileprivate static func shouldInlineCollection<E: SyntaxProtocol>(
        elements: [E],
        leftBracket: TokenSyntax,
        rightBracket: TokenSyntax,
        render: (E) -> String,
        context: Context
    ) -> Bool {
        guard !elements.isEmpty else { return false }
        let isMultiline = elements.contains { $0.leadingTrivia.containsNewlines }
            || rightBracket.leadingTrivia.containsNewlines
        guard isMultiline else { return false }

        // Comments anywhere inside the literal disqualify the rewrite — collapsing would lose them.
        // The opening bracket's own trailing trivia counts, because a comment there sits between
        // the bracket and the first element and the inline clears it outright.
        if leftBracket.trailingTrivia.hasAnyComments { return false }
        for element in elements
            where element.leadingTrivia.hasAnyComments
            || element.trailingTrivia.hasAnyComments
        { return false }
        if rightBracket.leadingTrivia.hasAnyComments { return false }

        let joined = elements.map(render).joined(separator: ", ")
        let openColumn = leftBracket
            .startLocation(converter: context.sourceLocationConverter).column
        let inlinedLength = openColumn - 1 + 1 + joined.count + 1
        return inlinedLength <= Self.maxLength(context: context)
    }

    /// Collapses a wrapped array literal onto one line when its joined form fits the print width.
    /// The trailing comma is dropped (single-line collection literals have no trailing comma per
    /// `multiElementCollectionTrailingCommas`'s default handling).
    fileprivate static func inlineArrayLiteral(
        _ node: ArrayExprSyntax,
        context: Context
    ) -> ExprSyntax {
        let elements = Array(node.elements)
        guard Self.shouldInlineCollection(
            elements: elements,
            leftBracket: node.leftSquare,
            rightBracket: node.rightSquare,
            render: { $0.expression.trimmedDescription },
            context: context
        ) else { return ExprSyntax(node) }

        Self.diagnose(.inlineCollectionLiteral, on: node.leftSquare, context: context)

        var newElements = elements
        let lastIdx = newElements.count - 1

        for i in newElements.indices {
            var element = MutableRef(&newElements[i])
            element.value.leadingTrivia = []
            element.value.expression = element.value.expression.with(\.leadingTrivia, [])
            element.value.expression = element.value.expression.with(\.trailingTrivia, [])

            if i == lastIdx {
                element.value.trailingComma = nil
                element.value.trailingTrivia = []
            } else if let comma = element.value.trailingComma {
                element.value.trailingComma = comma.with(\.trailingTrivia, [.spaces(1)])
            }
        }
        var result = node
        result.leftSquare = result.leftSquare.with(\.trailingTrivia, [])
        result.elements = ArrayElementListSyntax(newElements)
        result.rightSquare = result.rightSquare.with(\.leadingTrivia, [])
        return ExprSyntax(result)
    }

    fileprivate static func inlineDictionaryLiteral(
        _ node: DictionaryExprSyntax,
        context: Context
    ) -> ExprSyntax {
        guard let elementList = node.content.as(DictionaryElementListSyntax.self) else {
            return ExprSyntax(node)
        }
        let elements = Array(elementList)
        guard Self.shouldInlineCollection(
            elements: elements,
            leftBracket: node.leftSquare,
            rightBracket: node.rightSquare,
            render: { "\($0.key.trimmedDescription): \($0.value.trimmedDescription)" },
            context: context
        ) else { return ExprSyntax(node) }

        Self.diagnose(.inlineCollectionLiteral, on: node.leftSquare, context: context)

        var newElements = elements
        let lastIdx = newElements.count - 1

        for i in newElements.indices {
            var element = MutableRef(&newElements[i])
            element.value.leadingTrivia = []
            element.value.key = element.value.key.with(\.leadingTrivia, [])
            element.value.key = element.value.key.with(\.trailingTrivia, [])
            element.value.colon = element.value.colon.with(\.leadingTrivia, [])
            element.value.colon = element.value.colon.with(\.trailingTrivia, [.spaces(1)])
            element.value.value = element.value.value.with(\.leadingTrivia, [])
            element.value.value = element.value.value.with(\.trailingTrivia, [])

            if i == lastIdx {
                element.value.trailingComma = nil
                element.value.trailingTrivia = []
            } else if let comma = element.value.trailingComma {
                element.value.trailingComma = comma.with(\.trailingTrivia, [.spaces(1)])
            }
        }
        var result = node
        result.leftSquare = result.leftSquare.with(\.trailingTrivia, [])
        result.content = .elements(DictionaryElementListSyntax(newElements))
        result.rightSquare = result.rightSquare.with(\.leadingTrivia, [])
        return ExprSyntax(result)
    }

    fileprivate static func inlineClosure(
        _ node: ClosureExprSyntax,
        original: ClosureExprSyntax,
        context: Context
    ) -> ExprSyntax {
        guard node.statements.count == 1,
              let firstStmt = node.statements.first else { return ExprSyntax(node) }

        let isMultiline = firstStmt.leadingTrivia.containsNewlines
            || node.rightBrace.leadingTrivia.containsNewlines
            || node.leftBrace.trailingTrivia.containsNewlines
            || (node.signature?.trailingTrivia.containsNewlines ?? false)
        guard isMultiline else { return ExprSyntax(node) }

        if Self.commentPrecedesBrace(node.leftBrace, source: original.leftBrace) {
            return ExprSyntax(node)
        }
        if node.leftBrace.trailingTrivia.hasAnyComments { return ExprSyntax(node) }

        if let sig = node.signature {
            if sig.leadingTrivia.hasAnyComments { return ExprSyntax(node) }
            if sig.trailingTrivia.hasAnyComments { return ExprSyntax(node) }
        }
        if firstStmt.leadingTrivia.hasAnyComments { return ExprSyntax(node) }
        if firstStmt.trailingTrivia.hasAnyComments { return ExprSyntax(node) }
        if node.rightBrace.leadingTrivia.hasAnyComments { return ExprSyntax(node) }

        let bodyText = firstStmt.trimmedDescription
        let signatureText = node.signature.map { $0.trimmedDescription + " " } ?? ""
        let braceEndCol = node.leftBrace
            .endLocation(converter: context.sourceLocationConverter).column
        let prefix = braceEndCol - 1
        let totalLength = prefix + 1 + signatureText.count + bodyText.count + 2
        guard totalLength <= Self.maxLength(context: context) else { return ExprSyntax(node) }

        Self.diagnose(.inlineClosureBody, on: node.leftBrace, context: context)

        var result = node
        result.leftBrace = result.leftBrace.with(\.trailingTrivia, .space)

        if let sig = result.signature {
            result.signature = sig
                .with(\.leadingTrivia, [])
                .with(\.trailingTrivia, .space)
        }
        var items = Array(result.statements)
        items[0].leadingTrivia = []
        items[0].trailingTrivia = []
        result.statements = CodeBlockItemListSyntax(items)
        result.rightBrace = result.rightBrace.with(\.leadingTrivia, .space)
        return ExprSyntax(result)
    }

    fileprivate static func inlineObserver(
        _ node: AccessorDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let body = Self.inlinedBody(node.body, message: .inlineObserverBody, context: context)
        else { return DeclSyntax(node) }

        var result = node
        result.body = body
        return DeclSyntax(result)
    }
}

// MARK: - Scope hooks

extension LayoutSingleLineBodies {
    static func willEnter(_ node: IfExprSyntax, context: Context) {
        let isElseIf = Syntax(node).parent?.is(IfExprSyntax.self) == true
        let state = Self.state(context)
        state.indentStack.append(Self.computeBaseIndent(
            trivia: node.ifKeyword.leadingTrivia, isElseIf: isElseIf, state: state))
    }

    static func didExit(_: IfExprSyntax, context: Context) {
        _ = Self.state(context).indentStack.popLast()
    }

    static func willEnter(_ node: GuardStmtSyntax, context: Context) {
        let state = Self.state(context)
        state.indentStack.append(Self.computeBaseIndent(
            trivia: node.guardKeyword.leadingTrivia, isElseIf: false, state: state))
    }

    static func didExit(_: GuardStmtSyntax, context: Context) {
        _ = Self.state(context).indentStack.popLast()
    }

    static func willEnter(_ node: ForStmtSyntax, context: Context) {
        let state = Self.state(context)
        state.indentStack.append(Self.computeBaseIndent(
            trivia: node.forKeyword.leadingTrivia, isElseIf: false, state: state))
    }

    static func didExit(_: ForStmtSyntax, context: Context) {
        _ = Self.state(context).indentStack.popLast()
    }

    static func willEnter(_ node: WhileStmtSyntax, context: Context) {
        let state = Self.state(context)
        state.indentStack.append(Self.computeBaseIndent(
            trivia: node.whileKeyword.leadingTrivia, isElseIf: false, state: state))
    }

    static func didExit(_: WhileStmtSyntax, context: Context) {
        _ = Self.state(context).indentStack.popLast()
    }

    static func willEnter(_ node: RepeatStmtSyntax, context: Context) {
        let state = Self.state(context)
        state.indentStack.append(Self.computeBaseIndent(
            trivia: node.repeatKeyword.leadingTrivia, isElseIf: false, state: state))
    }

    static func didExit(_: RepeatStmtSyntax, context: Context) {
        _ = Self.state(context).indentStack.popLast()
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

    static let inlineClosureBody: Finding.Message = "place closure body on same line"

    static let inlineCollectionLiteral: Finding.Message =
        "place collection literal on same line as declaration"
}

// MARK: - Configuration

package struct LayoutSingleLineBodiesConfiguration: SyntaxRuleValue {
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
