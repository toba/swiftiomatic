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

    static func transform(
        _ node: FunctionCallExprSyntax,
        original _: FunctionCallExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Only process outermost nested call.
        guard !isInnerNestedCall(node) else { return ExprSyntax(node) }

        let mode = context.configuration[NestedCallLayout.self].mode

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

        // Fallback: collapse the leading newline so the sole arg hugs the opening paren,
        // re-indenting any continuation lines.
        if mode == .inline, let hugged = tryHugSingleArg(node, context: context) { return hugged }

        return ExprSyntax(node)
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
            args[
                i] = args[i]
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
                ))
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

    // MARK: - Shared Helpers

    /// Returns the number of characters before this node on the same line.
    private static func columnOffset(of node: some SyntaxProtocol) -> Int {
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
            for piece in t.trailingTrivia { count += piece.sourceLength.utf8Length }

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
