import SwiftSyntax

/// Convert trivial `map { $0.foo }` closures to keyPath-based syntax.
///
/// When a closure's only expression is a property access on `$0` , the closure can be replaced with
/// a keyPath expression: `map(\.foo)` . This is more concise and expressive.
///
/// Applies to `map` , `flatMap` , `compactMap` , `allSatisfy` , `filter` , and `contains(where:)` .
///
/// A key path literal converts to any function type `(Root) -> Value` (SE-0249), so the rule also
/// applies to a closure passed with an argument label, such as `displayName: { $0.name }` . A
/// closure that uses only `$0` can match only a function type with one parameter. A label that
/// names an action, such as `action:` , `perform:` or `onDismiss:` , usually takes a `Void` result,
/// which a key path cannot supply, so the rule skips it.
///
/// A trailing closure hides its argument label, and the rewrite has to spell it. The rule therefore
/// converts a trailing closure only for calls whose label it knows: `ForEach` ( `content:` ) and
/// `onGeometryChange` / `onScrollGeometryChange` ( `of:` ). For the geometry modifiers the
/// `action:` closure that follows becomes the trailing closure.
///
/// Only fires for simple property chains (not method calls, subscripts, or complex expressions).
///
/// Lint: A trivial `{ $0.property }` closure raises a warning.
///
/// Rewrite: The closure is replaced with a keyPath expression.
final class UseKeyPath: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 560

    override class var group: ConfigurationGroup? { .collections }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    private static let eligibleMethods: Set<String> = [
        "map", "flatMap", "compactMap", "allSatisfy", "filter", "contains",
    ]

    /// The argument label of the trailing closure for calls whose label the rule knows, and
    /// whether the call may carry further trailing closures after it
    private static let trailingClosureLabels: [String: (label: String, allowsLaterClosures: Bool)] =
        [
            "ForEach": ("content", false),
            "onGeometryChange": ("of", true),
            "onScrollGeometryChange": ("of", true),
        ]

    /// Argument labels whose closure usually returns `Void`
    private static let actionLabels: Set<String> = [
        "action", "perform", "set", "completion", "completionHandler", "handler", "body",
        "operation",
    ]

    static func transform(
        _ callNode: FunctionCallExprSyntax,
        original: FunctionCallExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        // Findings go on the closures of `original` . `callNode` is detached from the source tree
        // once another rule rewrites a child, so its positions no longer match the file.
        let converted = convertCollectionMethod(callNode, original: original, context: context)
        guard converted.as(FunctionCallExprSyntax.self) == callNode else { return converted }

        if let result = convertKnownTrailingClosure(callNode, original: original, context: context) {
            return result
        }
        return convertLabeledClosures(callNode, original: original, context: context)
            ?? ExprSyntax(callNode)
    }

    /// Converts the closure of `map` , `filter` , `contains(where:)` and the other collection
    /// methods
    private static func convertCollectionMethod(
        _ callNode: FunctionCallExprSyntax,
        original: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax {
        // Must be a method call (member access)
        guard let memberAccess = callNode.calledExpression.as(MemberAccessExprSyntax.self) else {
            return ExprSyntax(callNode)
        }

        let methodName = memberAccess.declName.baseName.text
        guard Self.eligibleMethods.contains(methodName) else { return ExprSyntax(callNode) }

        // Handle `contains(where:)` form
        if methodName == "contains" {
            return handleContainsWhere(
                callNode, original: original, memberAccess: memberAccess, context: context)
                ?? ExprSyntax(callNode)
        }

        // Handle trailing closure: map { $0.foo } Skip multiple trailing closures (can't use
        // keyPath with those)
        if let closure = callNode.trailingClosure,
           callNode.additionalTrailingClosures.isEmpty,
           let chain = extractPropertyChain(from: closure)
        {
            Self.diagnose(
                .useKeyPath(method: methodName), on: original.trailingClosure ?? closure,
                context: context)

            let keyPath = buildKeyPath(from: chain)
            let arg = LabeledExprSyntax(expression: ExprSyntax(keyPath))

            // Strip trailing trivia from calledExpression (space before trailing closure)
            var calledExpr = callNode.calledExpression
            calledExpr.trailingTrivia = []

            let newCall = FunctionCallExprSyntax(
                calledExpression: calledExpr,
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax([arg]),
                rightParen: .rightParenToken()
            )

            var result = ExprSyntax(newCall)
            result.leadingTrivia = callNode.leadingTrivia
            result.trailingTrivia = callNode.trailingTrivia
            return result
        }

        // Handle parenthesized closure: map({ $0.foo })
        if callNode.arguments.count == 1,
           let firstArg = callNode.arguments.first,
           firstArg.label == nil,
           let closureExpr = firstArg.expression.as(ClosureExprSyntax.self),
           let chain = extractPropertyChain(from: closureExpr)
        {
            Self.diagnose(
                .useKeyPath(method: methodName),
                on: original.arguments.first?.expression ?? firstArg.expression,
                context: context
            )

            let keyPath = buildKeyPath(from: chain)
            let newArg = firstArg.with(\.expression, ExprSyntax(keyPath))
            let newCall = callNode.with(\.arguments, LabeledExprListSyntax([newArg]))

            var result = ExprSyntax(newCall)
            result.leadingTrivia = callNode.leadingTrivia
            result.trailingTrivia = callNode.trailingTrivia
            return result
        }

        return ExprSyntax(callNode)
    }

    /// Converts the trailing closure of a call whose trailing-closure label the rule knows:
    /// `ForEach(items) { $0.row }` → `ForEach(items, content: \.row)`
    private static func convertKnownTrailingClosure(
        _ callNode: FunctionCallExprSyntax,
        original: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        guard let name = callNode.calleeBaseName,
              let known = trailingClosureLabels[name],
              let closure = callNode.trailingClosure,
              known.allowsLaterClosures || callNode.additionalTrailingClosures.isEmpty,
              let chain = extractPropertyChain(from: closure) else { return nil }

        Self.diagnose(
            .useKeyPath(method: name), on: original.trailingClosure ?? closure, context: context)

        var arguments = Array(callNode.arguments)
        var newArgument = LabeledExprSyntax(
            label: .identifier(known.label),
            colon: .colonToken(trailingTrivia: .space),
            expression: ExprSyntax(buildKeyPath(from: chain))
        )

        if let last = arguments.last {
            if last.trailingComma == nil {
                arguments[arguments.count - 1] = last.with(\.trailingComma, .commaToken())
                newArgument.leadingTrivia = .space
            } else {
                newArgument.leadingTrivia = last.leadingTrivia
                newArgument.trailingComma = .commaToken()
            }
        }
        arguments.append(newArgument)

        var result = callNode.with(\.arguments, LabeledExprListSyntax(arguments))
        result.calledExpression.trailingTrivia = []
        result.leftParen = callNode.leftParen ?? .leftParenToken()
        let rightParen = callNode.rightParen ?? .rightParenToken()

        if let next = callNode.additionalTrailingClosures.first {
            // the closure that followed becomes the trailing closure
            result.rightParen = rightParen.with(\.trailingTrivia, .space)
            result.trailingClosure = next.closure.with(\.leadingTrivia, [])
            result.additionalTrailingClosures = MultipleTrailingClosureElementListSyntax(
                Array(callNode.additionalTrailingClosures.dropFirst()))
        } else {
            result.rightParen = rightParen.with(\.trailingTrivia, closure.trailingTrivia)
            result.trailingClosure = nil
        }
        return ExprSyntax(result)
    }

    /// Converts every closure passed with an argument label that does not name an action:
    /// `displayName: { $0.name }` → `displayName: \.name`
    private static func convertLabeledClosures(
        _ callNode: FunctionCallExprSyntax,
        original: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        var changed = false
        let originalArguments = Array(original.arguments)
        let arguments = callNode.arguments.enumerated().map { index, argument -> LabeledExprSyntax in
            guard let label = argument.label?.text, !isActionLabel(label),
                  let closure = argument.expression.as(ClosureExprSyntax.self),
                  let chain = extractPropertyChain(from: closure) else { return argument }

            let method = callNode.calleeBaseName.map { "\($0)(\(label):)" } ?? "\(label):"
            let anchor = originalArguments.indices.contains(index)
                ? originalArguments[index].expression
                : ExprSyntax(closure)
            Self.diagnose(.useKeyPath(method: method), on: anchor, context: context)
            changed = true
            return argument.with(
                \.expression,
                ExprSyntax(buildKeyPath(from: chain))
                    .with(\.leadingTrivia, closure.leadingTrivia)
                    .with(\.trailingTrivia, closure.trailingTrivia)
            )
        }
        guard changed else { return nil }
        return ExprSyntax(callNode.with(\.arguments, LabeledExprListSyntax(arguments)))
    }

    /// Whether `label` names an action closure, such as `action:` or `onDismiss:`
    private static func isActionLabel(_ label: String) -> Bool {
        if actionLabels.contains(label) { return true }
        guard label.hasPrefix("on"), let next = label.dropFirst(2).first else { return false }
        return next.isUppercase
    }

    /// Handles `contains(where: { $0.foo })` → `contains(where: \.foo)`
    private static func handleContainsWhere(
        _ callNode: FunctionCallExprSyntax,
        original: FunctionCallExprSyntax,
        memberAccess _: MemberAccessExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        guard let firstArg = callNode.arguments.first,
              firstArg.label?.text == "where",
              let closureExpr = firstArg.expression.as(ClosureExprSyntax.self),
              let chain = extractPropertyChain(from: closureExpr) else { return nil }

        Self.diagnose(
            .useKeyPath(method: "contains(where:)"),
            on: original.arguments.first?.expression ?? firstArg.expression,
            context: context
        )

        let keyPath = buildKeyPath(from: chain)
        let newArg = firstArg.with(
            \.expression,
            ExprSyntax(keyPath)
                .with(\.leadingTrivia, firstArg.expression.leadingTrivia)
                .with(\.trailingTrivia, firstArg.expression.trailingTrivia)
        )
        return ExprSyntax(callNode.with(\.arguments, LabeledExprListSyntax([newArg])))
    }

    /// Extracts the property chain from a `{ $0.foo.bar }` closure, returning `["foo", "bar"]` .
    private static func extractPropertyChain(from closure: ClosureExprSyntax) -> [String]? {
        // Must have no explicit parameters (uses $0 shorthand)
        guard closure.signature == nil else { return nil }

        // Must have exactly one statement
        guard closure.statements.count == 1,
              let onlyItem = closure.statements.first,
              let expr = onlyItem.item.as(ExprSyntax.self) else { return nil }

        return extractChain(expr)
    }

    /// Recursively extracts property names from a `$0.a.b.c` chain.
    private static func extractChain(_ expr: ExprSyntax) -> [String]? {
        guard let memberAccess = expr.as(MemberAccessExprSyntax.self),
              let base = memberAccess.base else { return nil }

        let name = memberAccess.declName.baseName.text

        if let ref = base.as(DeclReferenceExprSyntax.self), ref.baseName.text == "$0" {
            return [name]
        }

        guard var chain = extractChain(base) else { return nil }
        chain.append(name)
        return chain
    }

    /// Builds a `KeyPathExprSyntax` from a property chain like `["foo", "bar"]` → `\.foo.bar` .
    private static func buildKeyPath(from chain: [String]) -> KeyPathExprSyntax {
        let components = chain.map { name in
            KeyPathComponentSyntax(
                period: .periodToken(),
                component: .property(KeyPathPropertyComponentSyntax(declName:
                        DeclReferenceExprSyntax(baseName: .identifier(name))))
            )
        }

        return .init(
            backslash: .backslashToken(),
            components: KeyPathComponentListSyntax(components)
        )
    }
}

fileprivate extension Finding.Message {
    static func useKeyPath(method: String) -> Finding.Message {
        "use keyPath expression instead of closure in '\(method)'"
    }
}
