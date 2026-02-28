import SwiftSyntax

/// §3: Finds callback-based, GCD, and legacy concurrency patterns
/// that can be modernized to structured concurrency.
///
/// When a `TypeResolver` is available, verifies that string-matched
/// `DispatchQueue` actually resolves to `Dispatch.DispatchQueue`,
/// upgrading confidence from medium to high.
final class ConcurrencyModernizationCheck: BaseCheck {
    /// DispatchQueue findings that can be verified via SourceKit.
    private struct DispatchQueueQuery {
        let offset: Int
        let findingIndex: Int
    }

    private var dispatchQueries: [DispatchQueueQuery] = []

    // MARK: - Completion handlers

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        for param in node.signature.parameterClause.parameters {
            if ConcurrencyDetectionHelpers.isCompletionHandlerParam(param) {
                addFinding(
                    at: node,
                    category: .concurrencyModernization,
                    severity: .medium,
                    message: "Function '\(node.name.text)' uses completion handler pattern",
                    suggestion: "Convert to async/await",
                    confidence: .high
                )
                break
            }
        }

        return .visitChildren
    }

    // MARK: - DispatchQueue usage

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

        if ConcurrencyDetectionHelpers.isDispatchQueueAsync(callee) {
            addFinding(
                at: node,
                category: .concurrencyModernization,
                severity: .medium,
                message: "DispatchQueue.async can be replaced with structured concurrency",
                suggestion: "Use Task { @MainActor in ... } or async function",
                confidence: .medium
            )

            if typeResolver?.isAvailable == true {
                let findingIdx = findings.count - 1
                dispatchQueries.append(
                    DispatchQueueQuery(
                        offset: node.calledExpression.positionAfterSkippingLeadingTrivia.utf8Offset,
                        findingIndex: findingIdx
                    )
                )
            }
        }

        // DispatchGroup
        if callee.contains("DispatchGroup") {
            addFinding(
                at: node,
                category: .concurrencyModernization,
                severity: .medium,
                message: "DispatchGroup can be replaced with TaskGroup",
                suggestion: "Use withTaskGroup or withThrowingTaskGroup",
                confidence: .medium
            )
        }

        // NSLock / os_unfair_lock
        if callee.contains("NSLock()") || callee.contains("os_unfair_lock") {
            addFinding(
                at: node,
                category: .concurrencyModernization,
                severity: .medium,
                message: "Lock-based synchronization can be replaced with Mutex",
                suggestion: "Use Mutex<Value> for state protection",
                confidence: .medium
            )
        }

        return .visitChildren
    }

    // MARK: - @unchecked Sendable

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if ConcurrencyDetectionHelpers.hasUncheckedSendable(node.inheritanceClause) {
            addFinding(
                at: node,
                category: .concurrencyModernization,
                severity: .medium,
                message:
                "Class '\(node.name.text)' uses @unchecked Sendable — check if Mutex would enable proper Sendable",
                confidence: .low
            )
        }
        return .visitChildren
    }

    override func resolveTypeQueries() async {
        guard let resolver = typeResolver, !dispatchQueries.isEmpty else { return }

        for query in dispatchQueries {
            guard query.findingIndex < findings.count else { continue }
            guard let resolved = await resolver.resolveType(inFile: filePath, offset: query.offset) else {
                continue
            }

            if resolved.moduleName == "Dispatch"
                || resolved.typeName.hasPrefix("Dispatch.DispatchQueue")
                || resolved.typeName == "DispatchQueue"
            {
                findings[query.findingIndex] = Finding(
                    category: findings[query.findingIndex].category,
                    severity: findings[query.findingIndex].severity,
                    file: findings[query.findingIndex].file,
                    line: findings[query.findingIndex].line,
                    column: findings[query.findingIndex].column,
                    message: findings[query.findingIndex].message,
                    suggestion: findings[query.findingIndex].suggestion,
                    confidence: .high
                )
            }
        }
    }
}
