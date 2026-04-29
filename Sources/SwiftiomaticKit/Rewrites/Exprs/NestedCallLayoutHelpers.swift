import SwiftSyntax

// sm:ignore-file: functionBodyLength

/// Stateless helpers for the inlined `NestedCallLayout` rule. The rule's
/// `static transform(_ FunctionCallExprSyntax, parent:context:)` overload
/// delegates to `applyNestedCallLayout(_:context:)`.

private let nestedCallLayoutIndentUnit = "    "

/// A level in the nested call chain.
private struct NestedCallLevel {
    let call: FunctionCallExprSyntax
}

func applyNestedCallLayout(
    _ node: FunctionCallExprSyntax,
    context: Context
) -> ExprSyntax {
    // Only process outermost nested call.
    guard !nestedCallLayoutIsInnerNestedCall(node) else { return ExprSyntax(node) }

    let mode = context.configuration[NestedCallLayout.self].mode

    if let chain = nestedCallLayoutCollectChain(node), chain.count >= 2 {
        switch mode {
        case .inline:
            // Chain strategies rebuild from trimmed descriptions, which
            // preserves args' internal whitespace. That only works when the
            // input is in canonical fully-nested form. For non-canonical
            // inputs (e.g., extra indent), hug instead.
            if nestedCallLayoutIsCanonicalFullyNested(node) {
                if let result = nestedCallLayoutInlineLayout(node, chain: chain, context: context) {
                    return result
                }
                return ExprSyntax(node)
            }
        case .wrap:
            return nestedCallLayoutWrapLayout(node, chain: chain, context: context)
        }
    }

    // Fallback: collapse the leading newline so the sole arg hugs the
    // opening paren, re-indenting any continuation lines.
    if mode == .inline, let hugged = nestedCallLayoutTryHugSingleArg(node, context: context) {
        return hugged
    }

    return ExprSyntax(node)
}

// MARK: - Nested Call Detection

/// Collects the chain of nested calls from outermost to innermost.
/// Returns nil if the structure isn't a clean nested call chain.
private func nestedCallLayoutCollectChain(
    _ node: FunctionCallExprSyntax
) -> [NestedCallLevel]? {
    var chain = [NestedCallLevel]()
    var current: FunctionCallExprSyntax? = node

    while let call = current {
        chain.append(NestedCallLevel(call: call))

        // Check if the sole argument is another function call.
        guard let inner = nestedCallLayoutSoleArgumentCall(call) else {
            break
        }
        current = inner
    }

    return chain.count >= 2 ? chain : nil
}

/// Returns the inner `FunctionCallExprSyntax` if this call has exactly one
/// argument list item whose expression is a function call. Bails when the
/// inner call's `calledExpression` spans multiple lines (e.g., a chained
/// member access) — that's not a clean nested call chain.
///
/// Also bails when either the outer or inner call carries a trailing
/// closure: the rebuild paths in this rule only stringify `arguments`, so
/// preserving a trailing closure isn't supported and a naive rebuild would
/// silently delete the closure body.
private func nestedCallLayoutSoleArgumentCall(
    _ call: FunctionCallExprSyntax
) -> FunctionCallExprSyntax? {
    if call.trailingClosure != nil || !call.additionalTrailingClosures.isEmpty { return nil }
    let args = call.arguments
    guard args.count == 1, let only = args.first else { return nil }
    guard let inner = only.expression.as(FunctionCallExprSyntax.self) else { return nil }
    if inner.trailingClosure != nil || !inner.additionalTrailingClosures.isEmpty { return nil }
    if inner.calledExpression.trimmedDescription.contains("\n") { return nil }
    return inner
}

/// Returns true if the call's sole argument is on a line indented exactly
/// one level past the call itself (canonical form), or the whole call fits
/// on one line. Non-canonical inputs route through the hug fallback.
private func nestedCallLayoutIsCanonicalFullyNested(
    _ node: FunctionCallExprSyntax
) -> Bool {
    guard node.description.contains("\n") else { return true }
    guard let firstArg = node.arguments.first else { return true }
    if !firstArg.leadingTrivia.containsNewlines { return true }
    let baseIndent = nestedCallLayoutLineIndentation(of: node)
    let argIndent = firstArg.leadingTrivia.indentation
    return argIndent.count == baseIndent.count + nestedCallLayoutIndentUnit.count
}

/// Returns true if this call is an inner part of a nested call chain
/// (i.e., it's the sole argument of a parent function call).
private func nestedCallLayoutIsInnerNestedCall(_ node: FunctionCallExprSyntax) -> Bool {
    guard let argElement = node.parent?.as(LabeledExprSyntax.self),
          let argList = argElement.parent?.as(LabeledExprListSyntax.self),
          argList.count == 1,
          let parentCall = argList.parent?.as(FunctionCallExprSyntax.self),
          nestedCallLayoutSoleArgumentCall(parentCall) != nil
    else { return false }
    return true
}

// MARK: - Inline Mode

private func nestedCallLayoutInlineLayout(
    _ node: FunctionCallExprSyntax,
    chain: [NestedCallLevel],
    context: Context
) -> ExprSyntax? {
    let baseIndent = nestedCallLayoutLineIndentation(of: node)
    let innermost = chain.last!.call
    let maxLength = context.configuration[LineLength.self]

    // Already fully inline.
    if !node.description.contains("\n") { return ExprSyntax(node) }

    let linePrefix = nestedCallLayoutColumnOffset(of: node)

    // Strategy 1: Fully inline.
    let fullyInlineLength = linePrefix + nestedCallLayoutBuildFullyInlineText(chain).count
    if fullyInlineLength <= maxLength {
        NestedCallLayout.diagnose(.collapseNestedCall, on: node, context: context)
        return nestedCallLayoutRebuildFullyInline(node, chain: chain)
    }

    // Strategy 2: Outer inline, inner arguments wrapped.
    let outerInlineLength = linePrefix + nestedCallLayoutBuildOuterInlinePrefix(chain).count
    if outerInlineLength <= maxLength {
        let innerArgs = nestedCallLayoutBuildWrappedArgs(
            innermost,
            indent: baseIndent + nestedCallLayoutIndentUnit
        )
        let strategy2MaxLine = innerArgs.split(separator: "\n").map(\.count).max() ?? 0
        if strategy2MaxLine <= maxLength {
            NestedCallLayout.diagnose(.collapseNestedCall, on: node, context: context)
            return nestedCallLayoutRebuildOuterInlineInnerWrapped(
                node, chain: chain, baseIndent: baseIndent
            )
        }
    }

    // Strategy 3: Fully wrapped — outer on new line, inner inline.
    let innerInlineLength =
        baseIndent.count + nestedCallLayoutIndentUnit.count
        + nestedCallLayoutBuildInnerInlineText(chain).count
    if innerInlineLength <= maxLength {
        NestedCallLayout.diagnose(.collapseNestedCall, on: node, context: context)
        return nestedCallLayoutRebuildFullyWrappedInnerInline(
            node, chain: chain, baseIndent: baseIndent
        )
    }

    // No chain strategy fits — let the caller fall back to the hug path.
    return nil
}

/// Joins arguments as inline text, stripping internal newlines.
private func nestedCallLayoutInlineArgText(_ call: FunctionCallExprSyntax) -> String {
    call.arguments.map(\.trimmedDescription).joined(separator: ", ")
}

/// Returns `"label: "` if the sole argument has a label, otherwise `""`.
private func nestedCallLayoutArgumentLabelPrefix(_ call: FunctionCallExprSyntax) -> String {
    guard let label = call.arguments.first?.label else { return "" }
    return label.trimmedDescription + ": "
}

/// Builds the text for a fully inlined version: `Outer(label: Inner(arg1: x, arg2: y))`
private func nestedCallLayoutBuildFullyInlineText(_ chain: [NestedCallLevel]) -> String {
    var result = ""
    for level in chain.dropLast() {
        result += level.call.calledExpression.trimmedDescription + "("
        result += nestedCallLayoutArgumentLabelPrefix(level.call)
    }
    let innermost = chain.last!.call
    result += innermost.calledExpression.trimmedDescription + "("
    result += nestedCallLayoutInlineArgText(innermost)
    result += String(repeating: ")", count: chain.count)
    return result
}

/// Builds just the prefix for strategy 2: `Outer(label: Inner(`
private func nestedCallLayoutBuildOuterInlinePrefix(_ chain: [NestedCallLevel]) -> String {
    var result = ""
    for level in chain.dropLast() {
        result += level.call.calledExpression.trimmedDescription + "("
        result += nestedCallLayoutArgumentLabelPrefix(level.call)
    }
    result += chain.last!.call.calledExpression.trimmedDescription + "("
    return result
}

/// Builds the inner call inline text for strategy 3: `Inner(arg1: x, arg2: y)`
private func nestedCallLayoutBuildInnerInlineText(_ chain: [NestedCallLevel]) -> String {
    var result = ""
    for level in chain.dropFirst().dropLast() {
        result += level.call.calledExpression.trimmedDescription + "("
        result += nestedCallLayoutArgumentLabelPrefix(level.call)
    }
    let innermost = chain.last!.call
    result += innermost.calledExpression.trimmedDescription + "("
    result += nestedCallLayoutInlineArgText(innermost)
    result += String(repeating: ")", count: chain.count - 1)
    return result
}

private func nestedCallLayoutBuildWrappedArgs(
    _ call: FunctionCallExprSyntax,
    indent: String
) -> String {
    call.arguments.map { indent + $0.trimmedDescription }.joined(separator: "\n")
}

/// Rebuilds as fully inline.
private func nestedCallLayoutRebuildFullyInline(
    _ node: FunctionCallExprSyntax,
    chain: [NestedCallLevel]
) -> ExprSyntax {
    let leadingTrivia = node.leadingTrivia
    let trailingTrivia = node.trailingTrivia

    // Build the innermost call first, then wrap outward.
    var result: ExprSyntax = nestedCallLayoutRebuildSingleCallInline(chain.last!.call)

    for level in chain.dropLast().reversed() {
        let original = level.call.arguments.first!
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
            )
        )
    }

    return result
        .with(\.leadingTrivia, leadingTrivia)
        .with(\.trailingTrivia, trailingTrivia)
}

/// Rebuilds a single call with its arguments inline (no newlines).
private func nestedCallLayoutRebuildSingleCallInline(
    _ call: FunctionCallExprSyntax
) -> ExprSyntax {
    var args = Array(call.arguments)
    for i in args.indices {
        // Remove newlines from leading trivia — just a space.
        args[i] = args[i]
            .with(\.leadingTrivia, i == 0 ? [] : .space)
            .with(\.trailingTrivia, [])
    }
    return ExprSyntax(
        FunctionCallExprSyntax(
            calledExpression: call.calledExpression.trimmed,
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax(args),
            rightParen: .rightParenToken()
        )
    )
}

/// Strategy 2: Outer calls inline, innermost args wrapped.
private func nestedCallLayoutRebuildOuterInlineInnerWrapped(
    _ node: FunctionCallExprSyntax,
    chain: [NestedCallLevel],
    baseIndent: String
) -> ExprSyntax {
    let leadingTrivia = node.leadingTrivia
    let trailingTrivia = node.trailingTrivia
    let argIndent = baseIndent + nestedCallLayoutIndentUnit

    // Build innermost call with wrapped args.
    let innermost = chain.last!.call
    var result: ExprSyntax = nestedCallLayoutRebuildCallWithWrappedArgs(
        innermost,
        argIndent: argIndent,
        closingIndent: baseIndent
    )

    // Wrap each outer level inline.
    for level in chain.dropLast().reversed() {
        let original = level.call.arguments.first!
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
            )
        )
    }

    return result
        .with(\.leadingTrivia, leadingTrivia)
        .with(\.trailingTrivia, trailingTrivia)
}

/// Strategy 3: Outer call wrapped, inner calls inline.
private func nestedCallLayoutRebuildFullyWrappedInnerInline(
    _ node: FunctionCallExprSyntax,
    chain: [NestedCallLevel],
    baseIndent: String
) -> ExprSyntax {
    let leadingTrivia = node.leadingTrivia
    let trailingTrivia = node.trailingTrivia
    let innerIndent = baseIndent + nestedCallLayoutIndentUnit

    // Build inner calls fully inline.
    var innerExpr: ExprSyntax = nestedCallLayoutRebuildSingleCallInline(chain.last!.call)
    for level in chain.dropFirst().dropLast().reversed() {
        let original = level.call.arguments.first!
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
            )
        )
    }

    // Wrap the outermost call.
    let outermost = chain.first!.call
    let outerOriginal = outermost.arguments.first!
    let arg: LabeledExprSyntax
    if let label = outerOriginal.label {
        arg = LabeledExprSyntax(
            label: label.with(\.leadingTrivia, .newline + Trivia(stringLiteral: innerIndent)),
            colon: outerOriginal.colon,
            expression: innerExpr.with(\.leadingTrivia, [])
        )
    } else {
        arg = LabeledExprSyntax(
            expression: innerExpr
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
        )
    )

    return result
        .with(\.leadingTrivia, leadingTrivia)
        .with(\.trailingTrivia, trailingTrivia)
}

// MARK: - Hug Fallback

/// Collapses the leading newline of a single-arg call so the arg hugs the
/// opening paren, re-indenting any continuation lines to baseIndent +
/// indentUnit and placing the closing paren back at baseIndent.
///
/// Returns nil when the call doesn't qualify (multiple args, single-line
/// arg, no surrounding parens, or already hugged).
private func nestedCallLayoutTryHugSingleArg(
    _ node: FunctionCallExprSyntax,
    context: Context
) -> ExprSyntax? {
    guard node.arguments.count == 1,
        let arg = node.arguments.first,
        node.leftParen != nil,
        let rightParen = node.rightParen,
        arg.leadingTrivia.containsNewlines,
        arg.description.contains("\n")
    else {
        return nil
    }

    let baseIndent = nestedCallLayoutLineIndentation(of: node)
    let argFirstLineIndent = arg.leadingTrivia.indentation
    let targetContinuationIndent = baseIndent + nestedCallLayoutIndentUnit

    // Already in canonical fully-nested form (arg indented exactly one
    // level past baseIndent) — leave as-is.
    if argFirstLineIndent.count == targetContinuationIndent.count { return nil }

    // Find the indent of the first continuation line inside the arg.
    var currentContinuationIndent: String?
    for token in arg.tokens(viewMode: .sourceAccurate).dropFirst() {
        if token.leadingTrivia.containsNewlines {
            currentContinuationIndent = token.leadingTrivia.indentation
            break
        }
    }

    // Anchor delta on first continuation indent so inner lines land at
    // baseIndent + indentUnit; arg's first token is hugged separately.
    let referenceIndentCount = currentContinuationIndent?.count ?? argFirstLineIndent.count
    let delta = targetContinuationIndent.count - referenceIndentCount
    if delta == 0 && argFirstLineIndent.isEmpty { return nil }

    let reindentedArg = nestedCallLayoutReindentLabeledExpr(arg, delta: delta)
        .with(\.leadingTrivia, [])

    // Preserve rightParen layout: only re-indent if it was on its own line.
    let newRightParen: TokenSyntax
    if rightParen.leadingTrivia.containsNewlines {
        newRightParen = rightParen.with(
            \.leadingTrivia, .newline + Trivia(stringLiteral: baseIndent))
    } else {
        newRightParen = rightParen
    }

    NestedCallLayout.diagnose(.collapseNestedCall, on: node, context: context)
    return ExprSyntax(
        node
            .with(\.arguments, [reindentedArg])
            .with(\.rightParen, newRightParen))
}

/// Walks all tokens in a labeled expression and shifts the indentation of
/// every leading-trivia newline by `delta` (positive = add spaces, negative
/// = remove spaces; clamped at zero).
private func nestedCallLayoutReindentLabeledExpr(
    _ arg: LabeledExprSyntax, delta: Int
) -> LabeledExprSyntax {
    guard delta != 0 else { return arg }
    let rewriter = NestedCallLayoutIndentShiftRewriter(delta: delta)
    return rewriter.rewrite(Syntax(arg)).cast(LabeledExprSyntax.self)
}

private final class NestedCallLayoutIndentShiftRewriter: SyntaxRewriter {
    let delta: Int

    init(delta: Int) {
        self.delta = delta
        super.init()
    }

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard token.leadingTrivia.containsNewlines else { return token }
        return token.with(\.leadingTrivia, token.leadingTrivia.shiftingNestedCallIndentation(by: delta))
    }
}

extension Trivia {
    /// Shifts the indentation (spaces/tabs) immediately following each newline
    /// piece by `delta`. Negative deltas clamp at zero.
    fileprivate func shiftingNestedCallIndentation(by delta: Int) -> Trivia {
        guard delta != 0 else { return self }
        var newPieces: [TriviaPiece] = []
        var afterNewline = false
        for piece in pieces {
            if afterNewline {
                switch piece {
                case .spaces(let n):
                    let newCount = Swift.max(0, n + delta)
                    if newCount > 0 { newPieces.append(.spaces(newCount)) }
                    afterNewline = false
                    continue
                case .tabs(let n):
                    let newCount = Swift.max(0, n + delta)
                    if newCount > 0 { newPieces.append(.tabs(newCount)) }
                    afterNewline = false
                    continue
                default:
                    afterNewline = false
                }
            }
            newPieces.append(piece)
            switch piece {
            case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                afterNewline = true
            default:
                break
            }
        }
        return .init(pieces: newPieces)
    }
}

// MARK: - Wrap Mode

private func nestedCallLayoutWrapLayout(
    _ node: FunctionCallExprSyntax,
    chain: [NestedCallLevel],
    context: Context
) -> ExprSyntax {
    let baseIndent = nestedCallLayoutLineIndentation(of: node)

    // Check if already in fully nested form.
    if nestedCallLayoutIsFullyNested(chain, baseIndent: baseIndent) {
        return ExprSyntax(node)
    }

    NestedCallLayout.diagnose(.expandNestedCall, on: node, context: context)
    return nestedCallLayoutRebuildFullyNested(node, chain: chain, baseIndent: baseIndent)
}

/// Checks if the chain is already in fully nested form.
private func nestedCallLayoutIsFullyNested(
    _ chain: [NestedCallLevel],
    baseIndent: String
) -> Bool {
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
private func nestedCallLayoutRebuildFullyNested(
    _ node: FunctionCallExprSyntax,
    chain: [NestedCallLevel],
    baseIndent: String
) -> ExprSyntax {
    let leadingTrivia = node.leadingTrivia
    let trailingTrivia = node.trailingTrivia
    let depth = chain.count

    // Build from innermost outward.
    let innermostDepth = depth - 1
    let innermostIndent = baseIndent
        + String(repeating: nestedCallLayoutIndentUnit, count: innermostDepth)
    let innermostArgIndent = innermostIndent + nestedCallLayoutIndentUnit

    let innermost = chain.last!.call
    var result: ExprSyntax = nestedCallLayoutRebuildCallWithWrappedArgs(
        innermost,
        argIndent: innermostArgIndent,
        closingIndent: innermostIndent
    )

    // Wrap each outer level.
    for (i, level) in chain.dropLast().enumerated().reversed() {
        let currentIndent = baseIndent + String(repeating: nestedCallLayoutIndentUnit, count: i)
        let argIndent = currentIndent + nestedCallLayoutIndentUnit

        let original = level.call.arguments.first!
        let arg: LabeledExprSyntax
        if let label = original.label {
            arg = LabeledExprSyntax(
                label: label.with(\.leadingTrivia, .newline + Trivia(stringLiteral: argIndent)),
                colon: original.colon,
                expression: result.with(\.leadingTrivia, [])
            )
        } else {
            arg = LabeledExprSyntax(
                expression: result
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
            )
        )
    }

    return result
        .with(\.leadingTrivia, leadingTrivia)
        .with(\.trailingTrivia, trailingTrivia)
}

// MARK: - Shared Helpers

/// Returns the number of characters before this node on the same line.
private func nestedCallLayoutColumnOffset(of node: some SyntaxProtocol) -> Int {
    guard let firstToken = node.firstToken(viewMode: .sourceAccurate) else { return 0 }
    var count = 0

    // Count characters in the first token's leading trivia after the last newline.
    for piece in firstToken.leadingTrivia.reversed() {
        switch piece {
        case .newlines, .carriageReturns, .carriageReturnLineFeeds: return count
        default: count += piece.sourceLength.utf8Length
        }
    }

    // Walk backward through previous tokens.
    var token = firstToken.previousToken(viewMode: .sourceAccurate)
    while let t = token {
        count += t.text.count
        for piece in t.trailingTrivia {
            count += piece.sourceLength.utf8Length
        }
        for piece in t.leadingTrivia.reversed() {
            switch piece {
            case .newlines, .carriageReturns, .carriageReturnLineFeeds: return count
            default: count += piece.sourceLength.utf8Length
            }
        }
        token = t.previousToken(viewMode: .sourceAccurate)
    }
    return count
}

/// Returns the indentation at the start of the line containing the node.
private func nestedCallLayoutLineIndentation(of node: some SyntaxProtocol) -> String {
    var token = node.firstToken(viewMode: .sourceAccurate)
    while let t = token {
        if t.leadingTrivia.containsNewlines {
            return t.leadingTrivia.indentation
        }
        token = t.previousToken(viewMode: .sourceAccurate)
    }
    // Start of file — no indentation.
    return ""
}

/// Rebuilds a call with each argument on its own line.
private func nestedCallLayoutRebuildCallWithWrappedArgs(
    _ call: FunctionCallExprSyntax,
    argIndent: String,
    closingIndent: String
) -> ExprSyntax {
    var args = Array(call.arguments)
    for i in args.indices {
        args[i] = args[i]
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
        )
    )
}

// MARK: - Finding Messages

extension Finding.Message {
    fileprivate static let collapseNestedCall: Finding.Message =
        "collapse nested call to fit on one line"

    fileprivate static let expandNestedCall: Finding.Message =
        "expand nested call onto separate lines"
}
