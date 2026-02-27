import SourceKitService
import SwiftSyntax

/// §3: Finds callback-based, GCD, and legacy concurrency patterns
/// that can be modernized to structured concurrency.
///
/// When a `TypeResolver` is available, verifies that string-matched
/// `DispatchQueue` actually resolves to `Dispatch.DispatchQueue`,
/// upgrading confidence from medium to high.
public final class ConcurrencyModernizationCheck: BaseCheck {

    /// DispatchQueue findings that can be verified via SourceKit.
    private struct DispatchQueueQuery {
        let offset: Int
        let findingIndex: Int
    }

    private var dispatchQueries: [DispatchQueueQuery] = []

    // MARK: - Completion handlers

    override public func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Find functions with @escaping completion handler parameters
        for param in node.signature.parameterClause.parameters {
            let paramName = param.firstName.text
            let isCompletion = paramName == "completion" || paramName == "completionHandler"
                || paramName == "handler" || paramName == "callback"

            if isCompletion, hasEscapingAttribute(param) {
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

    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

        // DispatchQueue.main.async / .global().async
        if callee.contains("DispatchQueue") && callee.hasSuffix(".async") {
            addFinding(
                at: node,
                category: .concurrencyModernization,
                severity: .medium,
                message: "DispatchQueue.async can be replaced with structured concurrency",
                suggestion: "Use Task { @MainActor in ... } or async function",
                confidence: .medium
            )

            // Queue for SourceKit verification to potentially upgrade confidence
            if typeResolver?.isAvailable == true {
                let findingIdx = findings.count - 1
                dispatchQueries.append(DispatchQueueQuery(
                    offset: node.calledExpression.positionAfterSkippingLeadingTrivia.utf8Offset,
                    findingIndex: findingIdx
                ))
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

    override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if hasUncheckedSendable(node.inheritanceClause) {
            addFinding(
                at: node,
                category: .concurrencyModernization,
                severity: .medium,
                message: "Class '\(node.name.text)' uses @unchecked Sendable — check if Mutex would enable proper Sendable",
                confidence: .low
            )
        }
        return .visitChildren
    }

    // MARK: - Helpers

    private func hasEscapingAttribute(_ param: FunctionParameterSyntax) -> Bool {
        // Check if the type has @escaping
        param.type.trimmedDescription.contains("@escaping")
    }

    private func hasUncheckedSendable(_ clause: InheritanceClauseSyntax?) -> Bool {
        guard let clause else { return false }
        return clause.trimmedDescription.contains("@unchecked Sendable")
    }

    override public func resolveTypeQueries() async {
        guard let resolver = typeResolver, !dispatchQueries.isEmpty else { return }

        for query in dispatchQueries {
            guard query.findingIndex < findings.count else { continue }
            guard let resolved = await resolver.resolveType(inFile: filePath, offset: query.offset) else {
                continue
            }

            // Verify it's actually Dispatch.DispatchQueue — upgrade confidence
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
