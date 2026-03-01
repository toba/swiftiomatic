import SwiftSyntax
import SwiftSyntaxBuilder

/// Collects violations when legacy C-style function calls are used
///
/// Matches calls against a dictionary of legacy function names and records a
/// violation at each call site. Paired with ``LegacyFunctionRewriter`` for
/// auto-correction.
class LegacyFunctionVisitor<Configuration: RuleConfiguration>: ViolationCollectingVisitor<
    Configuration,
> {
    @usableFromInline let legacyFunctions: [String: LegacyFunctionRewriteStrategy]

    /// Creates a visitor that watches for the specified legacy functions
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: The source file whose syntax tree will be traversed.
    ///   - legacyFunctions: A mapping from legacy function names to their ``LegacyFunctionRewriteStrategy``.
    @inlinable
    init(
        configuration: Configuration,
        file: SwiftSource,
        legacyFunctions: [String: LegacyFunctionRewriteStrategy],
    ) {
        self.legacyFunctions = legacyFunctions
        super.init(configuration: configuration, file: file)
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
        if node.isLegacyFunctionExpression(legacyFunctions: legacyFunctions) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

/// Strategy for rewriting a legacy C-style function call to its modern Swift equivalent
enum LegacyFunctionRewriteStrategy: Sendable {
    /// Rewrite as an equality check between the two arguments (e.g. `a == b`)
    case equal
    /// Rewrite as a property access on the argument (e.g. `a.isZero`)
    case property(name: String)
    /// Rewrite as a method call on the first argument with the remaining arguments
    ///
    /// When `reversed` is `true`, the method is called on the second argument
    /// with the first argument passed as a parameter.
    case function(name: String, argumentLabels: [String], reversed: Bool = false)

    fileprivate var expectedInitialArguments: Int {
        switch self {
            case .equal: 2
            case .property: 1
            case .function(name: _, let argumentLabels, reversed: _): argumentLabels.count + 1
        }
    }
}

/// Rewrites legacy C-style function calls to their modern Swift equivalents
///
/// Applies the ``LegacyFunctionRewriteStrategy`` for each matched call,
/// preserving leading and trailing trivia.
class LegacyFunctionRewriter<Configuration: RuleConfiguration>: ViolationCollectingRewriter<
    Configuration,
> {
    @usableFromInline let legacyFunctions: [String: LegacyFunctionRewriteStrategy]

    /// Creates a rewriter that corrects the specified legacy functions
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: The source file whose syntax tree will be rewritten.
    ///   - legacyFunctions: A mapping from legacy function names to their ``LegacyFunctionRewriteStrategy``.
    @inlinable
    init(
        configuration: Configuration,
        file: SwiftSource,
        legacyFunctions: [String: LegacyFunctionRewriteStrategy],
    ) {
        self.legacyFunctions = legacyFunctions
        super.init(configuration: configuration, file: file)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard node.isLegacyFunctionExpression(legacyFunctions: legacyFunctions),
              let funcName = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
        else {
            return super.visit(node)
        }
        numberOfCorrections += 1
        let trimmedArguments = node.arguments.map(\.trimmingTrailingComma)
        let rewriteStrategy = legacyFunctions[funcName]
        let expr: ExprSyntax
        switch rewriteStrategy {
            case .equal:
                expr = "\(trimmedArguments[0]) == \(trimmedArguments[1])"
            case let .property(name: propertyName):
                expr = "\(trimmedArguments[0]).\(raw: propertyName)"
            case let .function(
            name: functionName, argumentLabels: argumentLabels, reversed: reversed,
        ):
                let arguments = reversed ? trimmedArguments.reversed() : trimmedArguments
                let params = zip(argumentLabels, arguments.dropFirst())
                    .map { $0.isEmpty ? "\($1)" : "\($0): \($1)" }
                    .joined(separator: ", ")
                expr = "\(arguments[0]).\(raw: functionName)(\(raw: params))"
            case .none:
                return super.visit(node)
        }

        return
            expr
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
    }
}

private extension FunctionCallExprSyntax {
    func isLegacyFunctionExpression(
        legacyFunctions: [String: LegacyFunctionRewriteStrategy],
    ) -> Bool {
        guard let calledExpression = calledExpression.as(DeclReferenceExprSyntax.self),
              let rewriteStrategy = legacyFunctions[calledExpression.baseName.text],
              arguments.count == rewriteStrategy.expectedInitialArguments
        else {
            return false
        }
        return true
    }
}

private extension LabeledExprSyntax {
    var trimmingTrailingComma: LabeledExprSyntax {
        trimmed.with(\.trailingComma, nil).trimmed
    }
}
