import SourceKitService
import SwiftSyntax

/// §2: Finds functions that throw a single error type but declare untyped `throws`.
///
/// Scans function bodies for `throw` expressions and checks if they all throw
/// the same concrete error type. If so, suggests typed throws.
///
/// When a `TypeResolver` is available, resolves thrown variables (the `__unknown__`
/// fallback) to their actual types via cursorinfo.
public final class TypedThrowsCheck: BaseCheck {

    /// Pending throw-expression queries for post-walk resolution.
    private struct ThrowQuery {
        let funcName: String
        let offset: Int
        let funcNode: SyntaxProtocol
        let hasRethrows: Bool
        let knownTypes: Set<String>
    }

    private var throwQueries: [ThrowQuery] = []
    override public func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Only interested in functions that declare `throws` without a type
        guard let throwsClause = node.signature.effectSpecifiers?.throwsClause,
              throwsClause.type == nil
        else {
            return .visitChildren
        }

        // Collect all throw expressions in the function body
        guard let body = node.body else { return .visitChildren }
        let collector = ThrowCollector(viewMode: .sourceAccurate)
        collector.walk(body)

        guard !collector.thrownTypes.isEmpty else { return .visitChildren }

        let funcName = node.name.text

        // If __unknown__ is the only non-resolved type and we have a resolver, defer
        if collector.thrownTypes.contains("__unknown__"),
           typeResolver?.isAvailable == true
        {
            let knownTypes = collector.thrownTypes.subtracting(["__unknown__"])
            for offset in collector.unknownOffsets {
                throwQueries.append(ThrowQuery(
                    funcName: funcName,
                    offset: offset,
                    funcNode: node,
                    hasRethrows: collector.hasRethrows,
                    knownTypes: knownTypes
                ))
            }
            // If there are also known types with no unknowns, still report now
            if knownTypes.count == 1, collector.unknownOffsets.isEmpty {
                let errorType = knownTypes.first!
                addFinding(
                    at: node,
                    category: .typedThrows,
                    severity: .medium,
                    message: "Function '\(funcName)' throws only '\(errorType)' but declares untyped 'throws'",
                    suggestion: "func \(funcName)(...) throws(\(errorType))",
                    confidence: collector.hasRethrows ? .medium : .high
                )
            }
            return .visitChildren
        }

        // If all throws use the same error type, suggest typed throws
        if collector.thrownTypes.count == 1, let errorType = collector.thrownTypes.first {
            addFinding(
                at: node,
                category: .typedThrows,
                severity: .medium,
                message: "Function '\(funcName)' throws only '\(errorType)' but declares untyped 'throws'",
                suggestion: "func \(funcName)(...) throws(\(errorType))",
                confidence: collector.hasRethrows ? .medium : .high
            )
        }

        return .visitChildren
    }

    override public func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let throwsClause = node.signature.effectSpecifiers?.throwsClause,
              throwsClause.type == nil
        else {
            return .visitChildren
        }

        guard let body = node.body else { return .visitChildren }
        let collector = ThrowCollector(viewMode: .sourceAccurate)
        collector.walk(body)

        guard !collector.thrownTypes.isEmpty else { return .visitChildren }

        if collector.thrownTypes.count == 1, let errorType = collector.thrownTypes.first {
            addFinding(
                at: node,
                category: .typedThrows,
                severity: .medium,
                message: "Initializer throws only '\(errorType)' but declares untyped 'throws'",
                suggestion: "init(...) throws(\(errorType))",
                confidence: collector.hasRethrows ? .medium : .high
            )
        }

        return .visitChildren
    }

    override public func resolveTypeQueries() async {
        guard let resolver = typeResolver, !throwQueries.isEmpty else { return }

        // Group queries by function
        for query in throwQueries {
            guard let resolved = await resolver.resolveType(inFile: filePath, offset: query.offset) else {
                continue
            }

            // Combine resolved type with known types
            var allTypes = query.knownTypes
            allTypes.insert(resolved.typeName)

            if allTypes.count == 1, let errorType = allTypes.first {
                let location = query.funcNode.startLocation(converter: .init(
                    fileName: filePath,
                    tree: query.funcNode.root
                ))
                findings.append(Finding(
                    category: .typedThrows,
                    severity: .medium,
                    file: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Function '\(query.funcName)' throws only '\(errorType)' but declares untyped 'throws'",
                    suggestion: "func \(query.funcName)(...) throws(\(errorType))",
                    confidence: query.hasRethrows ? .medium : .high
                ))
            }
        }
    }
}

/// Collects thrown error types from throw expressions.
private final class ThrowCollector: SyntaxVisitor {
    var thrownTypes: Set<String> = []
    var hasRethrows = false
    /// Byte offsets of throw expressions with unknown types (for SourceKit resolution).
    var unknownOffsets: [Int] = []

    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        let expr = node.expression

        // Direct error construction: throw SomeError.case or throw SomeError(...)
        if let memberAccess = expr.as(MemberAccessExprSyntax.self),
           let base = memberAccess.base
        {
            thrownTypes.insert(base.trimmedDescription)
        } else if let funcCall = expr.as(FunctionCallExprSyntax.self) {
            thrownTypes.insert(funcCall.calledExpression.trimmedDescription)
        } else {
            // Can't determine type statically — might be a variable
            thrownTypes.insert("__unknown__")
            unknownOffsets.append(expr.positionAfterSkippingLeadingTrivia.utf8Offset)
        }

        return .skipChildren
    }

    override func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
        // If there's a `try` without `?`, the function rethrows
        if node.questionOrExclamationMark == nil {
            hasRethrows = true
        }
        return .visitChildren
    }

    // Don't descend into nested closures/functions — they have their own throw scope
    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}
