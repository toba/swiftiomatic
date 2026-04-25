import SwiftSyntax

/// Controls the layout of nested function/initializer calls where the sole
/// argument to one call is another call.
///
/// **Inline mode**: Collapses deeply nested calls into the most compact form
/// that fits the line width, trying each layout in order:
///
/// 1. Fully inline:
///    ```swift
///    result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
///    ```
///
/// 2. Outer inline, inner wrapped:
///    ```swift
///    result = ExprSyntax(ForceUnwrapExprSyntax(
///        expression: result,
///        trailingTrivia: trivia
///    ))
///    ```
///
/// 3. Fully wrapped (outer on new line, inner inline):
///    ```swift
///    result = ExprSyntax(
///        ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia)
///    )
///    ```
///
/// 4. Fully nested (no change).
///
/// **Wrap mode**: Expands any compact form into the fully nested form with each
/// call and its arguments on separate indented lines.
///
/// Lint: A nested call whose layout doesn't match the mode raises a warning.
///
/// Format: The call tree is reformatted to match the mode.
final class NestedCallLayout: RewriteSyntaxRule<NestedCallLayoutConfiguration> {
    override class var key: String { "nestedCallLayout" }
    override class var group: ConfigurationGroup? { .wrap }
    override class var defaultValue: NestedCallLayoutConfiguration {
        var config = NestedCallLayoutConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }

    private var mode: NestedCallLayoutConfiguration.Mode {
        context.configuration[NestedCallLayout.self].mode
    }

    private var maxLength: Int { context.configuration[LineLength.self] }
    private let indentUnit = "    "

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        // Only process outermost nested call.
        guard !isInnerNestedCall(node) else { return ExprSyntax(node) }

        // Must have a nested call chain (sole argument is a function call).
        guard let chain = collectNestedChain(node), chain.count >= 2 else {
            return ExprSyntax(node)
        }

        switch mode {
        case .inline: return inlineLayout(node, chain: chain)
        case .wrap: return wrapLayout(node, chain: chain)
        }
    }
}

// MARK: - Nested Call Detection

extension NestedCallLayout {

    /// A level in the nested call chain: the function call and its inner call argument (if any).
    private struct CallLevel {
        let call: FunctionCallExprSyntax
    }

    /// Collects the chain of nested calls from outermost to innermost.
    /// Returns nil if the structure isn't a clean nested call chain.
    private func collectNestedChain(_ node: FunctionCallExprSyntax) -> [CallLevel]? {
        var chain = [CallLevel]()
        var current: FunctionCallExprSyntax? = node

        while let call = current {
            chain.append(CallLevel(call: call))

            // Check if the sole argument is another function call.
            guard let inner = soleArgumentCall(call) else {
                break
            }
            current = inner
        }

        return chain.count >= 2 ? chain : nil
    }

    /// Returns the inner `FunctionCallExprSyntax` if this call has exactly one
    /// argument list item whose expression is a function call, or the sole
    /// positional argument is a function call.
    private func soleArgumentCall(_ call: FunctionCallExprSyntax) -> FunctionCallExprSyntax? {
        let args = call.arguments
        guard args.count == 1, let only = args.first else { return nil }
        return only.expression.as(FunctionCallExprSyntax.self)
    }

    /// Returns true if this call is an inner part of a nested call chain
    /// (i.e., it's the sole argument of a parent function call).
    private func isInnerNestedCall(_ node: FunctionCallExprSyntax) -> Bool {
        guard let argElement = node.parent?.as(LabeledExprSyntax.self),
              let argList = argElement.parent?.as(LabeledExprListSyntax.self),
              argList.count == 1,
              let parentCall = argList.parent?.as(FunctionCallExprSyntax.self),
              soleArgumentCall(parentCall) != nil
        else { return false }
        return true
    }
}

// MARK: - Inline Mode

extension NestedCallLayout {

    private func inlineLayout(_ node: FunctionCallExprSyntax, chain: [CallLevel]) -> ExprSyntax {
        let baseIndent = lineIndentation(of: node)
        let innermost = chain.last!.call

        // Check if already fully inline (no newlines in the whole expression).
        if !node.description.contains("\n") { return ExprSyntax(node) }

        // Characters before the function call on the same line.
        let linePrefix = columnOffset(of: node)

        // Strategy 1: Fully inline.
        let fullyInlineLength = linePrefix + buildFullyInlineText(chain).count
        if fullyInlineLength <= maxLength {
            diagnose(.collapseNestedCall, on: node)
            return rebuildFullyInline(node, chain: chain)
        }

        // Strategy 2: Outer inline, inner arguments wrapped.
        let outerInlineLength = linePrefix + buildOuterInlinePrefix(chain).count
        if outerInlineLength <= maxLength {
            let innerArgs = buildWrappedArgs(innermost, indent: baseIndent + indentUnit)
            let strategy2MaxLine = innerArgs.split(separator: "\n").map(\.count).max() ?? 0
            if strategy2MaxLine <= maxLength {
                diagnose(.collapseNestedCall, on: node)
                return rebuildOuterInlineInnerWrapped(node, chain: chain, baseIndent: baseIndent)
            }
        }

        // Strategy 3: Fully wrapped — outer on new line, inner inline.
        let innerInlineLength = baseIndent.count + indentUnit.count + buildInnerInlineText(chain).count
        if innerInlineLength <= maxLength {
            diagnose(.collapseNestedCall, on: node)
            return rebuildFullyWrappedInnerInline(node, chain: chain, baseIndent: baseIndent)
        }

        // Strategy 4: Nothing fits — leave as-is (fully nested).
        return ExprSyntax(node)
    }

    /// Joins arguments as inline text, stripping internal newlines.
    private func inlineArgText(_ call: FunctionCallExprSyntax) -> String {
        call.arguments.map(\.trimmedDescription).joined(separator: ", ")
    }

    /// Returns `"label: "` if the sole argument has a label, otherwise `""`.
    private func argumentLabelPrefix(_ call: FunctionCallExprSyntax) -> String {
        guard let label = call.arguments.first?.label else { return "" }
        return label.trimmedDescription + ": "
    }

    /// Builds the text for a fully inlined version: `Outer(label: Inner(arg1: x, arg2: y))`
    private func buildFullyInlineText(_ chain: [CallLevel]) -> String {
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
    private func buildOuterInlinePrefix(_ chain: [CallLevel]) -> String {
        var result = ""
        for level in chain.dropLast() {
            result += level.call.calledExpression.trimmedDescription + "("
            result += argumentLabelPrefix(level.call)
        }
        result += chain.last!.call.calledExpression.trimmedDescription + "("
        return result
    }

    /// Builds the inner call inline text for strategy 3: `Inner(arg1: x, arg2: y)`
    private func buildInnerInlineText(_ chain: [CallLevel]) -> String {
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

    private func buildWrappedArgs(_ call: FunctionCallExprSyntax, indent: String) -> String {
        call.arguments.map { indent + $0.trimmedDescription }.joined(separator: "\n")
    }

    /// Rebuilds as fully inline.
    private func rebuildFullyInline(
        _ node: FunctionCallExprSyntax,
        chain: [CallLevel]
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
                )
            )
        }

        return result
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }

    /// Rebuilds a single call with its arguments inline (no newlines).
    private func rebuildSingleCallInline(_ call: FunctionCallExprSyntax) -> ExprSyntax {
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
    private func rebuildOuterInlineInnerWrapped(
        _ node: FunctionCallExprSyntax,
        chain: [CallLevel],
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
                )
            )
        }

        return result
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }

    /// Strategy 3: Outer call wrapped, inner calls inline.
    private func rebuildFullyWrappedInnerInline(
        _ node: FunctionCallExprSyntax,
        chain: [CallLevel],
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
}

// MARK: - Wrap Mode

extension NestedCallLayout {

    private func wrapLayout(_ node: FunctionCallExprSyntax, chain: [CallLevel]) -> ExprSyntax {
        let baseIndent = lineIndentation(of: node)

        // Check if already in fully nested form.
        if isFullyNested(chain, baseIndent: baseIndent) {
            return ExprSyntax(node)
        }

        diagnose(.expandNestedCall, on: node)
        return rebuildFullyNested(node, chain: chain, baseIndent: baseIndent)
    }

    /// Checks if the chain is already in fully nested form.
    private func isFullyNested(_ chain: [CallLevel], baseIndent: String) -> Bool {
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
    private func rebuildFullyNested(
        _ node: FunctionCallExprSyntax,
        chain: [CallLevel],
        baseIndent: String
    ) -> ExprSyntax {
        let leadingTrivia = node.leadingTrivia
        let trailingTrivia = node.trailingTrivia
        let depth = chain.count

        // Build from innermost outward.
        let innermostDepth = depth - 1
        let innermostIndent = baseIndent + String(repeating: indentUnit, count: innermostDepth)
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
}

// MARK: - Shared Helpers

extension NestedCallLayout {

    /// Returns the number of characters before this node on the same line.
    private func columnOffset(of node: some SyntaxProtocol) -> Int {
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
    private func lineIndentation(of node: some SyntaxProtocol) -> String {
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
    private func rebuildCallWithWrappedArgs(
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
}

// MARK: - Finding Messages

extension Finding.Message {
    fileprivate static let collapseNestedCall: Finding.Message =
        "collapse nested call to fit on one line"

    fileprivate static let expandNestedCall: Finding.Message =
        "expand nested call onto separate lines"
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
    package var mode: Mode = .inline

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) { self.rewrite = rewrite }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        self.mode =
            try container.decodeIfPresent(Mode.self, forKey: .mode)
            ?? .inline
    }
}
