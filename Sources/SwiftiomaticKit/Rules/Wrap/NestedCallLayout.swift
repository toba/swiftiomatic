import SwiftSyntax

// sm:ignore functionBodyLength

/// Controls the layout of nested function/initializer calls where the sole argument to one call is
/// another call.
///
/// **Inline mode**: Collapses deeply nested calls into the most compact form that fits the line
/// width, trying each layout in order:
///
/// 1. Fully inline:
///    ```swift result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia)) ```
///
/// 2. Outer inline, inner wrapped:
///    ```swift result = ExprSyntax(ForceUnwrapExprSyntax( expression: result, trailingTrivia: trivia )) ```
///
/// 3. Fully wrapped (outer on new line, inner inline):
///    ```swift result = ExprSyntax( ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia) ) ```
///
/// 4. Fully nested (no change).
///
/// **Wrap mode**: Expands any compact form into the fully nested form with each call and its
/// arguments on separate indented lines.
///
/// Lint: A nested call whose layout doesn't match the mode raises a warning.
///
/// Rewrite: The call tree is reformatted to match the mode.
final class NestedCallLayout: StaticFormatRule<NestedCallLayoutConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: NestedCallLayoutConfiguration {
        var config = NestedCallLayoutConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }

    private static let indentUnit = "    "

    /// A level in the nested call chain.
    private struct Level {
        let call: FunctionCallExprSyntax
    }

    /// Returns the single argument of a chain-level call. `collectChain` only adds calls whose
    /// argument list has exactly one entry, so this is a safe invariant to assert.
    private static func soleArgument(of call: FunctionCallExprSyntax) -> LabeledExprSyntax {
        guard let arg = call.arguments.first else {
            preconditionFailure("nested call chain level must have exactly one argument")
        }
        return arg
    }

    static func transform(
        _ node: FunctionCallExprSyntax,
        original _: FunctionCallExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Only process outermost nested call.
        guard !isInnerNestedCall(node) else { return ExprSyntax(node) }

        let mode = context.configuration[NestedCallLayout.self].mode

        // SwiftUI-style modifier chains: when the outermost call's callee spans multiple lines
        // (e.g. `Text(name)…onHover { … }.background`), the chain-rebuild strategies below
        // mis-measure — `calledExpression.trimmedDescription` carries the whole multiline chain
        // and `columnOffset` / `lineIndentation` anchor on the chain's first token (the chain
        // root) rather than the modifier segment. That makes every inline strategy look too wide,
        // so the call wrongly *expands*. Handle these calls separately, measuring only the
        // modifier segment at its real rendered column. (prs-zf4)
        if calleeSpansMultipleLines(node) {
            if mode == .inline, let inlined = tryInlineModifierCallArgument(node, context: context) {
                return inlined
            }
            return ExprSyntax(node)
        }

        if let chain = collectChain(node), chain.count >= 2 {
            switch mode {
                case .inline:
                    // Chain strategies rebuild from trimmed descriptions, which preserves args'
                    // internal whitespace. That only works when the input is in canonical fully-nested
                    // form. For non-canonical inputs (e.g., extra indent), hug instead.
                    if isCanonicalFullyNested(node) {
                        if let result = inlineLayout(node, chain: chain, context: context) {
                            return result
                        }
                        return ExprSyntax(node)
                    }
                case .wrap: return wrapLayout(node, chain: chain, context: context)
            }
        }

        // Fallback A: collapse a wrapped multi-arg single-level call onto one line if it fits.
        // This also covers wrapped single-arg calls whose inlined form fits the line.
        if mode == .inline,
           let collapsed = tryCollapseCallToOneLine(node, context: context)
        {
            return collapsed
        }

        // Fallback B: collapse the leading newline so the sole arg hugs the opening paren,
        // re-indenting any continuation lines.
        if mode == .inline, let hugged = tryHugSingleArg(node, context: context) { return hugged }

        return ExprSyntax(node)
    }

    static func transform(
        _ node: MacroExpansionExprSyntax,
        original _: MacroExpansionExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        guard context.configuration[NestedCallLayout.self].mode == .inline else {
            return ExprSyntax(node)
        }
        return tryCollapseMacroExpansionToOneLine(node, context: context) ?? ExprSyntax(node)
    }

    // MARK: - Nested Call Detection

    /// Collects the chain of nested calls from outermost to innermost. Returns nil if the structure
    /// isn't a clean nested call chain.
    private static func collectChain(_ node: FunctionCallExprSyntax) -> [Level]? {
        var chain = [Level]()
        var current: FunctionCallExprSyntax? = node

        while let call = current {
            chain.append(Level(call: call))

            // Check if the sole argument is another function call.
            guard let inner = soleArgumentCall(call) else { break }
            current = inner
        }

        return chain.count >= 2 ? chain : nil
    }

    /// Returns the inner `FunctionCallExprSyntax` if this call has exactly one argument list item
    /// whose expression is a function call. Bails when the inner call's `calledExpression` spans
    /// multiple lines (e.g., a chained member access) — that's not a clean nested call chain.
    ///
    /// Also bails when either the outer or inner call carries a trailing closure: the rebuild paths
    /// in this rule only stringify `arguments` , so preserving a trailing closure isn't supported
    /// and a naive rebuild would silently delete the closure body.
    private static func soleArgumentCall(
        _ call: FunctionCallExprSyntax
    ) -> FunctionCallExprSyntax? {
        if call.trailingClosure != nil || !call.additionalTrailingClosures.isEmpty { return nil }
        let args = call.arguments
        guard args.count == 1, let only = args.first else { return nil }
        guard let inner = only.expression.as(FunctionCallExprSyntax.self) else { return nil }
        if inner.trailingClosure != nil || !inner.additionalTrailingClosures.isEmpty { return nil }
        return inner.calledExpression.trimmedDescription.contains("\n")
            ? nil
            : inner
    }

    /// Returns true if the call's sole argument is on a line indented exactly one level past the
    /// call itself (canonical form), or the whole call fits on one line. Non-canonical inputs route
    /// through the hug fallback.
    private static func isCanonicalFullyNested(_ node: FunctionCallExprSyntax) -> Bool {
        guard node.description.contains("\n") else { return true }
        guard let firstArg = node.arguments.first else { return true }
        if !firstArg.leadingTrivia.containsNewlines { return true }
        let baseIndent = lineIndentation(of: node)
        let argIndent = firstArg.leadingTrivia.indentation
        return argIndent.count == baseIndent.count + indentUnit.count
    }

    /// Returns true if this call is an inner part of a nested call chain (i.e., it's the sole
    /// argument of a parent function call).
    private static func isInnerNestedCall(_ node: FunctionCallExprSyntax) -> Bool {
        guard let argElement = node.parent?.as(LabeledExprSyntax.self),
              let argList = argElement.parent?.as(LabeledExprListSyntax.self),
              argList.count == 1,
              let parentCall = argList.parent?.as(FunctionCallExprSyntax.self),
              soleArgumentCall(parentCall) != nil else { return false }
        return true
    }

    // MARK: - Inline Mode

    private static func inlineLayout(
        _ node: FunctionCallExprSyntax,
        chain: [Level],
        context: Context
    ) -> ExprSyntax? {
        let baseIndent = lineIndentation(of: node)
        let innermost = chain.last!.call
        let maxLength = context.configuration[LineLength.self]

        // Already fully inline.
        if !node.description.contains("\n") { return ExprSyntax(node) }

        let linePrefix = columnOffset(of: node)

        // Strategy 1: Fully inline.
        let fullyInlineLength = linePrefix + buildFullyInlineText(chain).count

        if fullyInlineLength <= maxLength {
            Self.diagnose(.collapseNestedCall, on: node, context: context)
            return rebuildFullyInline(node, chain: chain)
        }

        // Strategy 2: Outer inline, inner arguments wrapped.
        let outerInlineLength = linePrefix + buildOuterInlinePrefix(chain).count

        if outerInlineLength <= maxLength {
            let innerArgs = buildWrappedArgs(
                innermost,
                indent: baseIndent + indentUnit
            )
            let strategy2MaxLine = innerArgs.split(separator: "\n").map(\.count).max() ?? 0

            if strategy2MaxLine <= maxLength {
                Self.diagnose(.collapseNestedCall, on: node, context: context)
                return rebuildOuterInlineInnerWrapped(
                    node, chain: chain, baseIndent: baseIndent
                )
            }
        }

        // Strategy 3: Fully wrapped — outer on new line, inner inline.
        let innerInlineLength = baseIndent.count + indentUnit.count
            + buildInnerInlineText(chain).count

        if innerInlineLength <= maxLength {
            Self.diagnose(.collapseNestedCall, on: node, context: context)
            return rebuildFullyWrappedInnerInline(
                node, chain: chain, baseIndent: baseIndent
            )
        }

        // No chain strategy fits — let the caller fall back to the hug path.
        return nil
    }

    /// Joins arguments as inline text, stripping internal newlines.
    private static func inlineArgText(_ call: FunctionCallExprSyntax) -> String {
        call.arguments.map(\.trimmedDescription).joined(separator: ", ")
    }

    /// Returns `"label: "` if the sole argument has a label, otherwise `""` .
    private static func argumentLabelPrefix(_ call: FunctionCallExprSyntax) -> String {
        guard let label = call.arguments.first?.label else { return "" }
        return label.trimmedDescription + ": "
    }

    /// Builds the text for a fully inlined version: `Outer(label: Inner(arg1: x, arg2: y))`
    private static func buildFullyInlineText(_ chain: [Level]) -> String {
        var result = ""

        for level in chain.dropLast() {
            result += level.call.calledExpression.trimmedDescription + "("
            result += argumentLabelPrefix(level.call)
        }
        let innermost = chain.last!.call
        result += innermost.calledExpression.trimmedDescription + "("
        result += inlineArgText(innermost)
        result += String(repeating: ")", count: chain.count)
        return result
    }

    /// Builds just the prefix for strategy 2: `Outer(label: Inner(`
    private static func buildOuterInlinePrefix(_ chain: [Level]) -> String {
        var result = ""

        for level in chain.dropLast() {
            result += level.call.calledExpression.trimmedDescription + "("
            result += argumentLabelPrefix(level.call)
        }
        result += chain.last!.call.calledExpression.trimmedDescription + "("
        return result
    }

    /// Builds the inner call inline text for strategy 3: `Inner(arg1: x, arg2: y)`
    private static func buildInnerInlineText(_ chain: [Level]) -> String {
        var result = ""

        for level in chain.dropFirst().dropLast() {
            result += level.call.calledExpression.trimmedDescription + "("
            result += argumentLabelPrefix(level.call)
        }
        let innermost = chain.last!.call
        result += innermost.calledExpression.trimmedDescription + "("
        result += inlineArgText(innermost)
        result += String(repeating: ")", count: chain.count - 1)
        return result
    }

    private static func buildWrappedArgs(
        _ call: FunctionCallExprSyntax,
        indent: String
    ) -> String {
        call.arguments.map { indent + $0.trimmedDescription }.joined(separator: "\n")
    }

    /// Rebuilds as fully inline.
    private static func rebuildFullyInline(
        _ node: FunctionCallExprSyntax,
        chain: [Level]
    ) -> ExprSyntax {
        let leadingTrivia = node.leadingTrivia
        let trailingTrivia = node.trailingTrivia

        // Build the innermost call first, then wrap outward.
        var result: ExprSyntax = rebuildSingleCallInline(chain.last!.call)

        for level in chain.dropLast().reversed() {
            let original = soleArgument(of: level.call)
            let arg = LabeledExprSyntax(
                label: original.label?.with(\.leadingTrivia, []),
                colon: original.colon,
                expression: result
            )
            result = ExprSyntax(
                FunctionCallExprSyntax(
                    calledExpression: level.call.calledExpression.trimmed,
                    leftParen: .leftParenToken(),
                    arguments: [arg],
                    rightParen: .rightParenToken()
                ))
        }

        return result
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }

    /// Rebuilds a single call with its arguments inline (no newlines).
    private static func rebuildSingleCallInline(
        _ call: FunctionCallExprSyntax
    ) -> ExprSyntax {
        var args = Array(call.arguments)

        for i in args.indices {
            // Remove newlines from leading trivia — just a space.
            var argument = MutableRef(&args[i])
            argument.value = argument.value
                .with(\.leadingTrivia, i == 0 ? [] : .space)
                .with(\.trailingTrivia, [])
        }
        return ExprSyntax(
            FunctionCallExprSyntax(
                calledExpression: call.calledExpression.trimmed,
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax(args),
                rightParen: .rightParenToken()
            ))
    }

    /// Strategy 2: Outer calls inline, innermost args wrapped.
    private static func rebuildOuterInlineInnerWrapped(
        _ node: FunctionCallExprSyntax,
        chain: [Level],
        baseIndent: String
    ) -> ExprSyntax {
        let leadingTrivia = node.leadingTrivia
        let trailingTrivia = node.trailingTrivia
        let argIndent = baseIndent + indentUnit

        // Build innermost call with wrapped args.
        let innermost = chain.last!.call
        var result: ExprSyntax = rebuildCallWithWrappedArgs(
            innermost,
            argIndent: argIndent,
            closingIndent: baseIndent
        )

        // Wrap each outer level inline.
        for level in chain.dropLast().reversed() {
            let original = soleArgument(of: level.call)
            let arg = LabeledExprSyntax(
                label: original.label?.with(\.leadingTrivia, []),
                colon: original.colon,
                expression: result
            )
            result = ExprSyntax(
                FunctionCallExprSyntax(
                    calledExpression: level.call.calledExpression.trimmed,
                    leftParen: .leftParenToken(),
                    arguments: [arg],
                    rightParen: .rightParenToken()
                ))
        }

        return result
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }

    /// Strategy 3: Outer call wrapped, inner calls inline.
    private static func rebuildFullyWrappedInnerInline(
        _ node: FunctionCallExprSyntax,
        chain: [Level],
        baseIndent: String
    ) -> ExprSyntax {
        let leadingTrivia = node.leadingTrivia
        let trailingTrivia = node.trailingTrivia
        let innerIndent = baseIndent + indentUnit

        // Build inner calls fully inline.
        var innerExpr: ExprSyntax = rebuildSingleCallInline(chain.last!.call)

        for level in chain.dropFirst().dropLast().reversed() {
            let original = soleArgument(of: level.call)
            let arg = LabeledExprSyntax(
                label: original.label,
                colon: original.colon,
                expression: innerExpr
            )
            innerExpr = ExprSyntax(
                FunctionCallExprSyntax(
                    calledExpression: level.call.calledExpression.trimmed,
                    leftParen: .leftParenToken(),
                    arguments: [arg],
                    rightParen: .rightParenToken()
                ))
        }

        // Wrap the outermost call.
        let outermost = chain.first!.call
        let outerOriginal = soleArgument(of: outermost)
        let arg: LabeledExprSyntax

        if let label = outerOriginal.label {
            arg = LabeledExprSyntax(
                label: label.with(\.leadingTrivia, .newline + Trivia(stringLiteral: innerIndent)),
                colon: outerOriginal.colon,
                expression: innerExpr.with(\.leadingTrivia, [])
            )
        } else {
            arg = LabeledExprSyntax(
                expression:
                    innerExpr
                    .with(\.leadingTrivia, .newline + Trivia(stringLiteral: innerIndent))
            )
        }
        let result = ExprSyntax(
            FunctionCallExprSyntax(
                calledExpression: outermost.calledExpression.trimmed,
                leftParen: .leftParenToken(),
                arguments: [arg],
                rightParen: .rightParenToken(
                    leadingTrivia: .newline + Trivia(stringLiteral: baseIndent)
                )
            ))

        return result
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }

    // MARK: - Modifier-Chain Calls

    /// Returns true when the call's `calledExpression` renders across multiple lines — e.g. a
    /// wrapped member-access modifier chain like `foo\n    .bar`. The chain-rebuild strategies
    /// assume a single-line callee, so such calls are routed through
    /// `tryInlineModifierCallArgument` instead. (prs-zf4)
    private static func calleeSpansMultipleLines(_ node: FunctionCallExprSyntax) -> Bool {
        node.calledExpression.trimmedDescription.contains("\n")
    }

    /// Collapses a modifier-chain call's argument list inline (`.method(a, b)`) when the modifier
    /// segment fits on its own line at its real rendered column.
    ///
    /// Measures only this call's own segment — anchored on the member-access period — so the
    /// multiline callee chain doesn't distort the width (which is what causes the chain-rebuild
    /// strategies to wrongly expand the call). Returns nil when the call doesn't qualify (no
    /// surrounding parens, no arguments, a trailing closure, internal comments, an already-inline
    /// body, a callee that isn't a member access, or a segment that wouldn't fit). (prs-zf4)
    private static func tryInlineModifierCallArgument(
        _ node: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
              node.leftParen != nil,
              let rightParen = node.rightParen,
              !node.arguments.isEmpty,
              node.trailingClosure == nil,
              node.additionalTrailingClosures.isEmpty,
              callBodySpansLines(arguments: node.arguments, rightParen: rightParen)
        else { return nil }

        if argumentsHaveComments(node.arguments, rightParen: rightParen) { return nil }

        let segment = memberAccess.period.text
            + memberAccess.declName.trimmedDescription
            + "(" + inlineArgText(node) + ")"
        guard !segment.contains("\n") else { return nil }

        let prefix = columnOffset(of: memberAccess.period)
        let maxLength = context.configuration[LineLength.self]
        guard prefix + segment.count <= maxLength else { return nil }

        Self.diagnose(.collapseNestedCall, on: memberAccess.declName, context: context)
        return ExprSyntax(collapseCallArguments(node))
    }

    // MARK: - Hug Fallback

    /// Collapses the leading newline of a single-arg call so the arg hugs the opening paren,
    /// re-indenting any continuation lines to baseIndent + indentUnit and placing the closing paren
    /// back at baseIndent.
    ///
    /// Returns nil when the call doesn't qualify (multiple args, single-line arg, no surrounding
    /// parens, or already hugged).
    private static func tryHugSingleArg(
        _ node: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        guard node.arguments.count == 1,
              let arg = node.arguments.first,
              node.leftParen != nil,
              let rightParen = node.rightParen,
              arg.leadingTrivia.containsNewlines,
              arg.description.contains("\n") else { return nil }

        let baseIndent = lineIndentation(of: node)
        let argFirstLineIndent = arg.leadingTrivia.indentation
        let targetContinuationIndent = baseIndent + indentUnit

        // Already in canonical fully-nested form (arg indented exactly one level past baseIndent) —
        // leave as-is.
        if argFirstLineIndent.count == targetContinuationIndent.count { return nil }

        // Find the indent of the first continuation line inside the arg.
        var currentContinuationIndent: String?

        for token in arg.tokens(viewMode: .sourceAccurate).dropFirst()
        where token.leadingTrivia.containsNewlines {
            currentContinuationIndent = token.leadingTrivia.indentation
            break
        }

        // Anchor delta on first continuation indent so inner lines land at baseIndent + indentUnit;
        // arg's first token is hugged separately.
        let referenceIndentCount = currentContinuationIndent?.count ?? argFirstLineIndent.count
        let delta = targetContinuationIndent.count - referenceIndentCount
        if delta == 0, argFirstLineIndent.isEmpty { return nil }

        let reindentedArg = reindentLabeledExpr(arg, delta: delta)
            .with(\.leadingTrivia, [])

        // Preserve rightParen layout: only re-indent if it was on its own line.
        let newRightParen: TokenSyntax
        newRightParen = rightParen.leadingTrivia.containsNewlines
            ? rightParen.with(
                \.leadingTrivia, .newline + Trivia(stringLiteral: baseIndent))
            : rightParen

        Self.diagnose(.collapseNestedCall, on: node, context: context)
        return ExprSyntax(
            node
                .with(\.arguments, [reindentedArg])
                .with(\.rightParen, newRightParen))
    }

    /// Walks all tokens in a labeled expression and shifts the indentation of every leading-trivia
    /// newline by `delta` (positive = add spaces, negative = remove spaces; clamped at zero).
    private static func reindentLabeledExpr(
        _ arg: LabeledExprSyntax,
        delta: Int
    ) -> LabeledExprSyntax {
        guard delta != 0 else { return arg }
        let rewriter = IndentShiftRewriter(delta: delta)
        return rewriter.rewrite(Syntax(arg)).cast(LabeledExprSyntax.self)
    }

    // MARK: - Wrap Mode

    private static func wrapLayout(
        _ node: FunctionCallExprSyntax,
        chain: [Level],
        context: Context
    ) -> ExprSyntax {
        let baseIndent = lineIndentation(of: node)

        // Check if already in fully nested form.
        if isFullyNested(chain, baseIndent: baseIndent) { return ExprSyntax(node) }

        Self.diagnose(.expandNestedCall, on: node, context: context)
        return rebuildFullyNested(node, chain: chain, baseIndent: baseIndent)
    }

    /// Checks if the chain is already in fully nested form.
    private static func isFullyNested(_ chain: [Level], baseIndent _: String) -> Bool {
        for (depth, level) in chain.enumerated() {
            let call = level.call

            // The left paren should be followed by a newline.
            guard let firstArg = call.arguments.first else { continue }

            // For non-innermost levels, the sole argument should be on a new line.
            if depth < chain.count - 1 {
                guard firstArg.leadingTrivia.containsNewlines else { return false }
                // Right paren should be on its own line.
                guard call.rightParen?.leadingTrivia.containsNewlines == true else { return false }
            } else {
                // Innermost: each argument should be on a new line.
                for arg in call.arguments {
                    guard arg.leadingTrivia.containsNewlines else { return false }
                }
                guard call.rightParen?.leadingTrivia.containsNewlines == true else { return false }
            }
        }
        return true
    }

    /// Rebuilds the entire chain in fully nested form.
    private static func rebuildFullyNested(
        _ node: FunctionCallExprSyntax,
        chain: [Level],
        baseIndent: String
    ) -> ExprSyntax {
        let leadingTrivia = node.leadingTrivia
        let trailingTrivia = node.trailingTrivia
        let depth = chain.count

        // Build from innermost outward.
        let innermostDepth = depth - 1
        let innermostIndent = baseIndent
            + String(repeating: indentUnit, count: innermostDepth)
        let innermostArgIndent = innermostIndent + indentUnit

        let innermost = chain.last!.call
        var result: ExprSyntax = rebuildCallWithWrappedArgs(
            innermost,
            argIndent: innermostArgIndent,
            closingIndent: innermostIndent
        )

        // Wrap each outer level.
        for (i, level) in chain.dropLast().enumerated().reversed() {
            let currentIndent = baseIndent + String(repeating: indentUnit, count: i)
            let argIndent = currentIndent + indentUnit

            let original = soleArgument(of: level.call)
            let arg: LabeledExprSyntax

            if let label = original.label {
                arg = LabeledExprSyntax(
                    label: label.with(\.leadingTrivia, .newline + Trivia(stringLiteral: argIndent)),
                    colon: original.colon,
                    expression: result.with(\.leadingTrivia, [])
                )
            } else {
                arg = LabeledExprSyntax(
                    expression:
                        result
                        .with(\.leadingTrivia, .newline + Trivia(stringLiteral: argIndent))
                )
            }

            result = ExprSyntax(
                FunctionCallExprSyntax(
                    calledExpression: level.call.calledExpression.trimmed,
                    leftParen: .leftParenToken(),
                    arguments: [arg],
                    rightParen: .rightParenToken(
                        leadingTrivia: .newline + Trivia(stringLiteral: currentIndent)
                    )
                ))
        }

        return result
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }

    // MARK: - Multi-arg / Macro Collapse

    /// Collapses a wrapped function call onto one line when the result fits within the configured
    /// line length. Skips calls with trailing closures or any internal comments (collapsing would
    /// drop them).
    private static func tryCollapseCallToOneLine(
        _ node: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        guard node.leftParen != nil,
              node.rightParen != nil,
              node.trailingClosure == nil,
              node.additionalTrailingClosures.isEmpty,
              !node.arguments.isEmpty,
              callBodySpansLines(arguments: node.arguments, rightParen: node.rightParen)
        else { return nil }

        if argumentsHaveComments(node.arguments, rightParen: node.rightParen) { return nil }

        let collapsed = collapseCallArguments(node)
        let collapsedText = collapsed.trimmedDescription
        guard !collapsedText.contains("\n") else { return nil }

        let linePrefix = columnOffset(of: node)
        let maxLength = context.configuration[LineLength.self]
        guard linePrefix + collapsedText.count <= maxLength else { return nil }

        Self.diagnose(.collapseNestedCall, on: node, context: context)
        return ExprSyntax(collapsed)
    }

    private static func tryCollapseMacroExpansionToOneLine(
        _ node: MacroExpansionExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        guard node.leftParen != nil,
              node.rightParen != nil,
              node.trailingClosure == nil,
              node.additionalTrailingClosures.isEmpty,
              !node.arguments.isEmpty,
              callBodySpansLines(arguments: node.arguments, rightParen: node.rightParen)
        else { return nil }

        if argumentsHaveComments(node.arguments, rightParen: node.rightParen) { return nil }

        let collapsed = collapseMacroArguments(node)
        let collapsedText = collapsed.trimmedDescription
        guard !collapsedText.contains("\n") else { return nil }

        let linePrefix = columnOffset(of: node)
        let maxLength = context.configuration[LineLength.self]
        guard linePrefix + collapsedText.count <= maxLength else { return nil }

        Self.diagnose(.collapseNestedCall, on: node, context: context)
        return ExprSyntax(collapsed)
    }

    private static func callBodySpansLines(
        arguments: LabeledExprListSyntax,
        rightParen: TokenSyntax?
    ) -> Bool {
        for arg in arguments {
            if arg.leadingTrivia.containsNewlines { return true }
            if arg.trailingComma?.trailingTrivia.containsNewlines == true { return true }
            if arg.trailingTrivia.containsNewlines { return true }
        }
        return rightParen?.leadingTrivia.containsNewlines == true
    }

    private static func argumentsHaveComments(
        _ arguments: LabeledExprListSyntax,
        rightParen: TokenSyntax?
    ) -> Bool {
        for arg in arguments {
            if arg.leadingTrivia.hasAnyComments { return true }
            if arg.trailingTrivia.hasAnyComments { return true }
            if arg.trailingComma?.trailingTrivia.hasAnyComments == true { return true }
        }
        if rightParen?.leadingTrivia.hasAnyComments == true { return true }
        return false
    }

    private static func inlinedArguments(
        _ arguments: LabeledExprListSyntax
    ) -> LabeledExprListSyntax {
        var args = Array(arguments)
        let lastIdx = args.count - 1
        for i in args.indices {
            var argument = MutableRef(&args[i])
            argument.value = argument.value
                .with(\.leadingTrivia, i == 0 ? [] : .space)
                .with(\.trailingTrivia, [])
            if i == lastIdx {
                argument.value.trailingComma = nil
            } else if let comma = argument.value.trailingComma {
                argument.value.trailingComma = comma.with(\.trailingTrivia, [])
            }
        }
        return LabeledExprListSyntax(args)
    }

    private static func collapseCallArguments(
        _ node: FunctionCallExprSyntax
    ) -> FunctionCallExprSyntax {
        var result = node
        if let leftParen = result.leftParen {
            result.leftParen = leftParen.with(\.trailingTrivia, [])
        }
        result.arguments = inlinedArguments(node.arguments)
        if let rightParen = result.rightParen {
            result.rightParen = rightParen.with(\.leadingTrivia, [])
        }
        return result
    }

    private static func collapseMacroArguments(
        _ node: MacroExpansionExprSyntax
    ) -> MacroExpansionExprSyntax {
        var result = node
        if let leftParen = result.leftParen {
            result.leftParen = leftParen.with(\.trailingTrivia, [])
        }
        result.arguments = inlinedArguments(node.arguments)
        if let rightParen = result.rightParen {
            result.rightParen = rightParen.with(\.leadingTrivia, [])
        }
        return result
    }

    // MARK: - Shared Helpers

    /// Returns the number of grapheme clusters before this node on the same line.
    ///
    /// Counts in grapheme clusters everywhere so that multi-byte characters in tokens or trivia
    /// (e.g. non-ASCII function names) don't inflate the column past the visible width.
    private static func columnOffset(of node: some SyntaxProtocol) -> Int {
        guard let firstToken = node.firstToken(viewMode: .sourceAccurate) else { return 0 }

        // Accumulate the source text on the current line that precedes the node, walking
        // backwards and stopping at the most recent newline.
        var lineFragment = ""

        func prependStoppingAtNewline(_ text: String) -> Bool {
            if let nlIndex = text.lastIndex(where: { $0 == "\n" || $0 == "\r" }) {
                lineFragment = String(text[text.index(after: nlIndex)...]) + lineFragment
                return true
            }
            lineFragment = text + lineFragment
            return false
        }

        if prependStoppingAtNewline(firstToken.leadingTrivia.description) {
            return lineFragment.count
        }

        var token = firstToken.previousToken(viewMode: .sourceAccurate)
        while let t = token {
            lineFragment = t.text + t.trailingTrivia.description + lineFragment
            if prependStoppingAtNewline(t.leadingTrivia.description) {
                return lineFragment.count
            }
            token = t.previousToken(viewMode: .sourceAccurate)
        }
        return lineFragment.count
    }

    /// Returns the indentation at the start of the line containing the node.
    private static func lineIndentation(of node: some SyntaxProtocol) -> String {
        var token = node.firstToken(viewMode: .sourceAccurate)

        while let t = token {
            if t.leadingTrivia.containsNewlines { return t.leadingTrivia.indentation }
            token = t.previousToken(viewMode: .sourceAccurate)
        }
        // Start of file — no indentation.
        return ""
    }

    /// Rebuilds a call with each argument on its own line.
    private static func rebuildCallWithWrappedArgs(
        _ call: FunctionCallExprSyntax,
        argIndent: String,
        closingIndent: String
    ) -> ExprSyntax {
        var args = Array(call.arguments)

        for i in args.indices {
            args[
                i] = args[i]
                .with(\.leadingTrivia, .newline + Trivia(stringLiteral: argIndent))
                .with(\.trailingTrivia, [])
        }
        return ExprSyntax(
            FunctionCallExprSyntax(
                calledExpression: call.calledExpression.trimmed,
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax(args),
                rightParen: .rightParenToken(
                    leadingTrivia: .newline + Trivia(stringLiteral: closingIndent)
                )
            ))
    }
}

// MARK: - Configuration

package struct NestedCallLayoutConfiguration: SyntaxRuleValue {
    package enum Mode: String, Codable, Sendable {
        /// Collapse nested calls to the most compact form that fits.
        case inline
        /// Expand nested calls to fully nested form.
        case wrap
    }

    package var rewrite = true
    package var lint: Lint = .warn
    /// `inline` collapses nested calls to the most compact form that fits; `wrap` expands them to
    /// fully nested form.
    package var mode: Mode = .inline

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        mode = try container.decodeIfPresent(Mode.self, forKey: .mode)
            ?? .inline
    }
}

// MARK: - Indent Shifter

private final class IndentShiftRewriter: SyntaxRewriter {
    let delta: Int

    init(delta: Int) {
        self.delta = delta
        super.init()
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard token.leadingTrivia.containsNewlines else { return token }
        return token.with(
            \.leadingTrivia, token.leadingTrivia.shiftingNestedCallIndentation(by: delta))
    }
}

fileprivate extension Trivia {
    /// Shifts the indentation (spaces/tabs) immediately following each newline piece by `delta` .
    /// Negative deltas clamp at zero.
    func shiftingNestedCallIndentation(by delta: Int) -> Trivia {
        guard delta != 0 else { return self }
        var newPieces: [TriviaPiece] = []
        var afterNewline = false

        for piece in pieces {
            if afterNewline {
                switch piece {
                    case let .spaces(n):
                        let newCount = Swift.max(0, n + delta)
                        if newCount > 0 { newPieces.append(.spaces(newCount)) }
                        afterNewline = false
                        continue
                    case let .tabs(n):
                        let newCount = Swift.max(0, n + delta)
                        if newCount > 0 { newPieces.append(.tabs(newCount)) }
                        afterNewline = false
                        continue
                    default: afterNewline = false
                }
            }
            newPieces.append(piece)

            switch piece {
                case .newlines, .carriageReturns, .carriageReturnLineFeeds: afterNewline = true
                default: break
            }
        }
        return .init(pieces: newPieces)
    }
}

// MARK: - Finding Messages

fileprivate extension Finding.Message {
    static let collapseNestedCall: Finding.Message = "collapse nested call to fit on one line"

    static let expandNestedCall: Finding.Message = "expand nested call onto separate lines"
}
