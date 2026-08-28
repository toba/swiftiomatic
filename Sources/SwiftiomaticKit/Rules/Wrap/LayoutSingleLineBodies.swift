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
    static let rewriteOrder = 1200

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

    static func maxLength(context: Context) -> Int { context.configuration[LineLength.self] }

    static func transform(
        _ node: IfExprSyntax,
        original: IfExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapIf(node, original: original, context: context)
            case .inline: Self.inlineIf(node, original: original, context: context)
        }
    }

    static func transform(
        _ node: GuardStmtSyntax,
        original: GuardStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapGuard(node, original: original, context: context)
            case .inline: Self.inlineGuard(node, original: original, context: context)
        }
    }

    static func transform(
        _ node: FunctionDeclSyntax,
        original: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapFunction(node, original: original, context: context)
            case .inline: Self.inlineFunction(node, original: original, context: context)
        }
    }

    static func transform(
        _ node: InitializerDeclSyntax,
        original: InitializerDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapInit(node, original: original, context: context)
            case .inline: Self.inlineInit(node, original: original, context: context)
        }
    }

    static func transform(
        _ node: SubscriptDeclSyntax,
        original: SubscriptDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapSubscript(node, original: original, context: context)
            case .inline: Self.inlineSubscript(node, original: original, context: context)
        }
    }

    static func transform(
        _ node: ForStmtSyntax,
        original: ForStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapFor(node, original: original, context: context)
            case .inline: Self.inlineFor(node, original: original, context: context)
        }
    }

    static func transform(
        _ node: WhileStmtSyntax,
        original: WhileStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapWhile(node, original: original, context: context)
            case .inline: Self.inlineWhile(node, original: original, context: context)
        }
    }

    static func transform(
        _ node: RepeatStmtSyntax,
        original: RepeatStmtSyntax,
        parent _: Syntax?,
        context: Context
    ) -> StmtSyntax {
        switch Self.mode(context: context) {
            case .wrap: Self.wrapRepeat(node, original: original, context: context)
            case .inline: Self.inlineRepeat(node, original: original, context: context)
        }
    }

    static func transform(
        _ node: PatternBindingSyntax,
        original: PatternBindingSyntax,
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        switch Self.mode(context: context) {
            case .wrap:
                Self.wrapProperty(node, original: original, parent: parent, context: context)
            case .inline:
                Self.inlineProperty(node, original: original, parent: parent, context: context)
        }
    }

    static func transform(
        _ node: ArrayExprSyntax,
        original: ArrayExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard Self.mode(context: context) == .inline else { return ExprSyntax(node) }
        return Self.inlineArrayLiteral(node, original: original, context: context)
    }

    static func transform(
        _ node: DictionaryExprSyntax,
        original: DictionaryExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard Self.mode(context: context) == .inline else { return ExprSyntax(node) }
        return Self.inlineDictionaryLiteral(node, original: original, context: context)
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
        original: AccessorDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        guard Self.mode(context: context) == .inline,
              node.accessorSpecifier.tokenKind == .keyword(.didSet)
                  || node.accessorSpecifier.tokenKind == .keyword(.willSet)
        else {
            return DeclSyntax(node)
        }

        return Self.inlineObserver(node, original: original, context: context)
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

    /// The opening brace of an `else` block in the parsed tree, or nil when the original carries no
    /// `else` block. A finding anchors on it, so it has to come from the parsed tree.
    fileprivate static func elseBrace(of node: IfExprSyntax) -> TokenSyntax? {
        guard case let .codeBlock(block) = node.elseBody else { return nil }
        return block.leftBrace
    }

    fileprivate static func wrapIf(
        _ node: IfExprSyntax,
        original: IfExprSyntax,
        context: Context
    ) -> ExprSyntax {
        // willEnter has already pushed self's baseIndent onto the stack.
        let baseIndent = Self.state(context).indentStack.last ?? ""

        let needsBodyWrap = node.body.bodyNeedsWrapping

        if needsBodyWrap {
            Self.diagnose(.wrapConditionalBody, on: original.body.leftBrace, context: context)
        }

        var result = node
        if needsBodyWrap { result.body = result.body.wrappingBody(baseIndent: baseIndent) }

        if let elseBody = node.elseBody {
            switch elseBody {
                case .ifExpr: break
                case var .codeBlock(block):
                    let needsElseWrap = block.bodyNeedsWrapping

                    if needsElseWrap {
                        Self.diagnose(
                            .wrapConditionalBody,
                            on: Self.elseBrace(of: original),
                            context: context
                        )
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
    ///   - original: the same statement as it sits in the parsed tree, which is what the finding
    ///     anchors on
    ///   - body: the path to the body to wrap
    ///   - message: the finding the rewrite emits
    /// - Returns: the node with a wrapped body, or the node unchanged when the body already wraps
    fileprivate static func wrappingStatement<Node: SyntaxProtocol>(
        _ node: Node,
        original: Node,
        body: WritableKeyPath<Node, CodeBlockSyntax>,
        message: Finding.Message,
        context: Context
    ) -> Node {
        guard node[keyPath: body].bodyNeedsWrapping else { return node }

        Self.diagnose(message, on: original[keyPath: body].leftBrace, context: context)

        let baseIndent = Self.state(context).indentStack.last ?? ""
        var result = node
        result[keyPath: body] = node[keyPath: body].wrappingBody(baseIndent: baseIndent)
        return result
    }

    /// Wraps a declaration's body onto its own lines, indented from its introducer keyword
    ///
    /// - Parameters:
    ///   - node: the declaration that owns the body
    ///   - original: the same declaration as it sits in the parsed tree, which is what the finding
    ///     anchors on
    ///   - body: the path to the body to wrap
    ///   - keyword: the path to the keyword whose own indentation the body indents from
    /// - Returns: the node with a wrapped body, or the node unchanged when the body already wraps
    fileprivate static func wrappingDeclaration<Node: SyntaxProtocol>(
        _ node: Node,
        original: Node,
        body: WritableKeyPath<Node, CodeBlockSyntax?>,
        keyword: KeyPath<Node, TokenSyntax>,
        context: Context
    ) -> Node {
        guard let block = node[keyPath: body], block.bodyNeedsWrapping else { return node }

        Self.diagnose(.wrapFunctionBody, on: original[keyPath: body]?.leftBrace, context: context)

        let baseIndent = node[keyPath: keyword].leadingTrivia.indentation
        var result = node
        result[keyPath: body] = block.wrappingBody(baseIndent: baseIndent)
        return result
    }

    fileprivate static func wrapGuard(
        _ node: GuardStmtSyntax,
        original: GuardStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        StmtSyntax(Self.wrappingStatement(
            node, original: original, body: \.body, message: .wrapConditionalBody, context: context)
        )
    }

    fileprivate static func wrapFunction(
        _ node: FunctionDeclSyntax,
        original: FunctionDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(Self.wrappingDeclaration(
            node, original: original, body: \.body, keyword: \.funcKeyword, context: context))
    }

    fileprivate static func wrapInit(
        _ node: InitializerDeclSyntax,
        original: InitializerDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        DeclSyntax(Self.wrappingDeclaration(
            node, original: original, body: \.body, keyword: \.initKeyword, context: context))
    }

    fileprivate static func wrapSubscript(
        _ node: SubscriptDeclSyntax,
        original: SubscriptDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let accessorBlock = node.accessorBlock,
              case let .getter(statements) = accessorBlock.accessors,
              !statements.isEmpty else { return DeclSyntax(node) }

        guard let firstStmt = statements.first,
              !firstStmt.leadingTrivia.containsNewlines else { return DeclSyntax(node) }

        let closingOnNewLine = accessorBlock.rightBrace.leadingTrivia.containsNewlines
        guard !closingOnNewLine else { return DeclSyntax(node) }

        Self.diagnose(.wrapFunctionBody, on: original.accessorBlock?.leftBrace, context: context)

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
        original: ForStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        StmtSyntax(Self.wrappingStatement(
            node, original: original, body: \.body, message: .wrapLoopBody, context: context))
    }

    fileprivate static func wrapWhile(
        _ node: WhileStmtSyntax,
        original: WhileStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        StmtSyntax(Self.wrappingStatement(
            node, original: original, body: \.body, message: .wrapLoopBody, context: context))
    }

    fileprivate static func wrapRepeat(
        _ node: RepeatStmtSyntax,
        original: RepeatStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        StmtSyntax(Self.wrappingStatement(
            node, original: original, body: \.body, message: .wrapLoopBody, context: context))
    }

    /// Puts an accessor block's elements onto their own lines, indented one level in
    ///
    /// Both accessor shapes wrap the same way, and they differ in the element type alone. The
    /// caller passes the elements it holds and the closure that puts them back.
    ///
    /// - Parameters:
    ///   - block: the accessor block to rewrite
    ///   - elements: the block's elements, which the getter shape holds as statements and the
    ///     accessor shape holds as declarations. An empty list returns the block unchanged.
    ///   - baseIndent: the indentation of the line the enclosing declaration starts on
    ///   - rebuild: puts the re-indented elements back into an accessors value
    fileprivate static func wrappingAccessorBlock<E: SyntaxProtocol>(
        _ block: AccessorBlockSyntax,
        elements: [E],
        baseIndent: String,
        rebuild: ([E]) -> AccessorBlockSyntax.Accessors
    ) -> AccessorBlockSyntax {
        guard !elements.isEmpty else { return block }

        var result = block
        result.leftBrace = result.leftBrace.with(
            \.trailingTrivia,
            result.leftBrace.trailingTrivia.trimmingTrailingWhitespace
        )

        var items = elements
        items[0].leadingTrivia = .newline + Trivia(stringLiteral: baseIndent + "    ")
        let lastIdx = items.count - 1
        items[lastIdx].trailingTrivia = items[lastIdx].trailingTrivia.trimmingTrailingWhitespace
        result.accessors = rebuild(items)

        result.rightBrace = result.rightBrace.with(
            \.leadingTrivia,
            .newline + Trivia(stringLiteral: baseIndent)
        )
        return result
    }

    fileprivate static func wrapProperty(
        _ node: PatternBindingSyntax,
        original: PatternBindingSyntax,
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        guard let accessorBlock = node.accessorBlock,
              !accessorBlock.rightBrace.leadingTrivia.containsNewlines else { return node }

        var result = node

        switch accessorBlock.accessors {
            case let .getter(statements):
                guard let firstStmt = statements.first,
                      !firstStmt.leadingTrivia.containsNewlines else { return node }

                result.accessorBlock = Self.wrappingAccessorBlock(
                    accessorBlock,
                    elements: Array(statements),
                    baseIndent: Self.resolveVarIndent(parent: parent),
                    rebuild: { .getter(CodeBlockItemListSyntax($0)) }
                )

            case let .accessors(accessors):
                guard accessors.contains(where: { $0.body != nil }),
                      let firstAccessor = accessors.first,
                      !firstAccessor.leadingTrivia.containsNewlines else { return node }

                result.accessorBlock = Self.wrappingAccessorBlock(
                    accessorBlock,
                    elements: Array(accessors),
                    baseIndent: Self.resolveVarIndent(parent: parent),
                    rebuild: { .accessors(AccessorDeclListSyntax($0)) }
                )
        }

        Self.diagnose(.wrapPropertyBody, on: original.accessorBlock?.leftBrace, context: context)
        return result
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
    static func commentPrecedesBrace(
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
        return statementTrailing.hasAnyComments || block.rightBrace.leadingTrivia.hasAnyComments
    }

    /// The number of characters that precede the opening brace on its own line
    ///
    /// The brace must still be attached to the tree the file was parsed into. Both readings map a
    /// position through the source location converter, and a detached tree starts at offset 0, so a
    /// detached brace reports a line and a column that belong to another part of the file.
    /// `previousToken` also returns nil at a detached root, which hides the leading-newline branch.
    ///
    /// - Parameters:
    ///   - leftBrace: the opening brace as it sits in the parsed tree
    /// Collapses a getter accessor block onto one line
    ///
    /// The subscript path and the property path both end here. Neither one needs the statement list
    /// rebuilt, so the caller passes the list it already holds.
    ///
    /// - Parameters:
    ///   - block: the accessor block to collapse
    ///   - statements: the block's single statement, in a list
    fileprivate static func inliningGetter(
        _ block: AccessorBlockSyntax,
        statements: [CodeBlockItemSyntax]
    ) -> AccessorBlockSyntax {
        var result = block
        result.leftBrace = result.leftBrace.with(\.trailingTrivia, .space)

        var items = statements
        items[0].leadingTrivia = []
        items[0].trailingTrivia = []
        result.accessors = .getter(CodeBlockItemListSyntax(items))

        result.rightBrace = result.rightBrace.with(\.leadingTrivia, .space)
        return result
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
    ///   - originalBrace: the body's opening brace as it sits in the parsed tree. It carries the
    ///     position the width measurement and the finding both need. Nil refuses the inline.
    ///   - message: the finding the rewrite emits
    ///   - suffixLength: characters that follow the closing brace, as `repeat` 's while clause has
    fileprivate static func inlinedBody(
        _ body: CodeBlockSyntax?,
        originalBrace: TokenSyntax?,
        message: Finding.Message,
        suffixLength: Int = 0,
        context: Context
    ) -> CodeBlockSyntax? {
        guard let body, let originalBrace, Self.canInline(body) else { return nil }

        let prefix = Self.prefixLength(to: originalBrace, context: context)
        guard Self.fitsInline(
            prefixLength: prefix,
            bodyText: Self.singleStatementText(body),
            suffixLength: suffixLength,
            context: context
        ) else { return nil }

        Self.diagnose(message, on: originalBrace, context: context)
        return Self.inliningBody(body)
    }

    // Widths the layout writes around a folded conditional body. The head covers the keyword, the
    // space after it, and everything between the last condition and the brace. The wrapped brace
    // covers the brace line the layout writes once the condition list wraps.
    fileprivate static let ifHeadWidth = 5  // "if " and " {"
    fileprivate static let whileHeadWidth = 8  // "while " and " {"
    fileprivate static let guardHeadWidth = 13  // "guard " and " else {"
    fileprivate static let wrappedBraceWidth = 1  // "{"
    fileprivate static let wrappedElseBraceWidth = 6  // "else {"

    /// Whether the layout can put a folded conditional body on a line that fits
    ///
    /// Three questions decide it, and each is answered from the configuration rather than from the
    /// column the source carries:
    ///
    /// 1. Does the whole folded statement fit on one line? Then the brace stays on the keyword line
    ///    and the fold survives.
    /// 2. If not, the condition list wraps. A list whose continuations sit at a column of their own
    ///    buries the brace, because a brace folded onto that column no longer reads as separate
    ///    from the condition. The fold is refused.
    /// 3. Otherwise the layout drops the brace to the statement's own indent, and the fold survives
    ///    when it fits there.
    ///
    /// - Parameters:
    ///   - conditions: the condition list as it sits in the parsed tree
    ///   - original: the statement as it sits in the parsed tree, which carries the depth the
    ///     layout indents it to
    ///   - wrapping: how the layout indents the condition list once it wraps
    ///   - headWidth: the width the keyword and the brace add on the unwrapped line
    ///   - wrappedBraceWidth: the width of the brace line the layout writes once the list wraps
    ///   - bodyText: the single statement the fold puts between the braces
    fileprivate static func conditionalFoldFits(
        conditions: ConditionElementListSyntax,
        original: some SyntaxProtocol,
        wrapping: ConditionWrapping,
        headWidth: Int,
        wrappedBraceWidth: Int,
        bodyText: String,
        context: Context
    ) -> Bool {
        let maxLength = Self.maxLength(context: context)
        let indent = syntacticIndentColumn(of: Syntax(original), context: context)
        let folded = 1 + bodyText.count + 2  // " <statement> }"

        if indent + headWidth + joinedWidth(of: conditions) + folded <= maxLength { return true }
        guard wrapping.isUniform else { return false }
        return indent + wrappedBraceWidth + folded <= maxLength
    }

    fileprivate static func inlineIf(
        _ node: IfExprSyntax,
        original: IfExprSyntax,
        context: Context
    ) -> ExprSyntax {
        guard node.elseBody == nil,
              Self.canInline(node.body),
              Self.conditionalFoldFits(
                  conditions: original.conditions,
                  original: original,
                  wrapping: ifConditionWrapping(original.conditions, config: context.configuration),
                  headWidth: Self.ifHeadWidth,
                  wrappedBraceWidth: Self.wrappedBraceWidth,
                  bodyText: Self.singleStatementText(node.body),
                  context: context
              ) else { return ExprSyntax(node) }

        Self.diagnose(.inlineConditionalBody, on: original.body.leftBrace, context: context)
        var result = node
        result.body = Self.inliningBody(node.body)
        return ExprSyntax(result)
    }

    fileprivate static func inlineGuard(
        _ node: GuardStmtSyntax,
        original: GuardStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        guard Self.canInline(node.body),
              Self.conditionalFoldFits(
                  conditions: original.conditions,
                  original: original,
                  wrapping: guardConditionWrapping(
                      original.conditions,
                      config: context.configuration
                  ),
                  headWidth: Self.guardHeadWidth,
                  wrappedBraceWidth: Self.wrappedElseBraceWidth,
                  bodyText: Self.singleStatementText(node.body),
                  context: context
              ) else { return StmtSyntax(node) }

        Self.diagnose(.inlineConditionalBody, on: original.body.leftBrace, context: context)
        var result = node
        result.body = Self.inliningBody(node.body)
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
        original: FunctionDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        if Self.hasWrappedGenericWhereClause(node.genericWhereClause) {
            return Self.wrapFunction(node, original: original, context: context)
        }
        guard let body = Self.inlinedBody(
            node.body,
            originalBrace: original.body?.leftBrace,
            message: .inlineFunctionBody,
            context: context
        ) else { return DeclSyntax(node) }

        var result = node
        result.body = body
        return DeclSyntax(result)
    }

    fileprivate static func inlineInit(
        _ node: InitializerDeclSyntax,
        original: InitializerDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        if Self.hasWrappedGenericWhereClause(node.genericWhereClause) {
            return Self.wrapInit(node, original: original, context: context)
        }
        guard let body = Self.inlinedBody(
            node.body,
            originalBrace: original.body?.leftBrace,
            message: .inlineFunctionBody,
            context: context
        ) else { return DeclSyntax(node) }

        var result = node
        result.body = body
        return DeclSyntax(result)
    }

    fileprivate static func inlineSubscript(
        _ node: SubscriptDeclSyntax,
        original: SubscriptDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        if Self.hasWrappedGenericWhereClause(node.genericWhereClause) {
            return Self.wrapSubscript(node, original: original, context: context)
        }
        // A missing original brace refuses the inline outright, because the width measurement below
        // reads a position and a detached token answers with a position from another part of the
        // file. The wrap path keeps going on the same nil, since it reads no position and loses
        // only the finding's location.
        guard let accessorBlock = node.accessorBlock,
              let originalBrace = original.accessorBlock?.leftBrace,
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
        let prefix = Self.prefixLength(to: originalBrace, context: context)

        guard Self.fitsInline(prefixLength: prefix, bodyText: bodyText, context: context) else {
            return DeclSyntax(node)
        }

        Self.diagnose(.inlineFunctionBody, on: originalBrace, context: context)

        var result = node
        result.accessorBlock = Self.inliningGetter(accessorBlock, statements: Array(statements))
        return DeclSyntax(result)
    }

    fileprivate static func inlineFor(
        _ node: ForStmtSyntax,
        original: ForStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        guard let body = Self.inlinedBody(
            node.body,
            originalBrace: original.body.leftBrace,
            message: .inlineLoopBody,
            context: context
        ) else { return StmtSyntax(node) }

        var result = node
        result.body = body
        return StmtSyntax(result)
    }

    fileprivate static func inlineWhile(
        _ node: WhileStmtSyntax,
        original: WhileStmtSyntax,
        context: Context
    ) -> StmtSyntax {
        guard Self.canInline(node.body),
              Self.conditionalFoldFits(
                  conditions: original.conditions,
                  original: original,
                  wrapping: whileConditionWrapping(
                      original.conditions,
                      config: context.configuration
                  ),
                  headWidth: Self.whileHeadWidth,
                  wrappedBraceWidth: Self.wrappedBraceWidth,
                  bodyText: Self.singleStatementText(node.body),
                  context: context
              ) else { return StmtSyntax(node) }

        Self.diagnose(.inlineLoopBody, on: original.body.leftBrace, context: context)
        var result = node
        result.body = Self.inliningBody(node.body)
        return StmtSyntax(result)
    }

    fileprivate static func inlineRepeat(
        _ node: RepeatStmtSyntax,
        original: RepeatStmtSyntax,
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
            originalBrace: original.body.leftBrace,
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
        original: PatternBindingSyntax,
        parent: Syntax?,
        context: Context
    ) -> PatternBindingSyntax {
        // A missing original brace refuses the inline outright, for the reason inlineSubscript
        // records.
        guard let accessorBlock = node.accessorBlock,
              let originalBrace = original.accessorBlock?.leftBrace else { return node }

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
                    let prefix = Self.prefixLength(to: originalBrace, context: context)
                    guard Self.fitsInline(
                        prefixLength: prefix,
                        bodyText: bodyText,
                        context: context
                    ) else { return node }
                } else {
                    let estimate = varIndent.count + node.trimmedDescription.count
                    guard estimate <= Self.maxLength(context: context) else { return node }
                }

                Self.diagnose(.inlinePropertyBody, on: originalBrace, context: context)

                var result = node
                result.accessorBlock = Self.inliningGetter(
                    accessorBlock, statements: Array(statements))
                return result

            case let .accessors(accessors):
                return Self.inlineAccessors(
                    node,
                    block: accessorBlock,
                    originalBrace: originalBrace,
                    accessors: Array(accessors),
                    parent: parent,
                    context: context
                )
        }
    }

    /// - Parameters:
    ///   - originalBrace: the accessor block's opening brace as it sits in the parsed tree. It
    ///     carries the position the width measurement and the finding both need.
    fileprivate static func inlineAccessors(
        _ node: PatternBindingSyntax,
        block accessorBlock: AccessorBlockSyntax,
        originalBrace: TokenSyntax,
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
            let prefix = Self.prefixLength(to: originalBrace, context: context)
            let total = prefix + 1 + joined.count + 2
            guard total <= Self.maxLength(context: context) else { return node }
        } else {
            let varIndent = Self.resolveVarIndent(parent: parent)
            let estimate = varIndent.count + node.trimmedDescription.count
            guard estimate <= Self.maxLength(context: context) else { return node }
        }

        Self.diagnose(.inlinePropertyBody, on: originalBrace, context: context)

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

    fileprivate static func inlineObserver(
        _ node: AccessorDeclSyntax,
        original: AccessorDeclSyntax,
        context: Context
    ) -> DeclSyntax {
        guard let body = Self.inlinedBody(
            node.body,
            originalBrace: original.body?.leftBrace,
            message: .inlineObserverBody,
            context: context
        ) else { return DeclSyntax(node) }

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
