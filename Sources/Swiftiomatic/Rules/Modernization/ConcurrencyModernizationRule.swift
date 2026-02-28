import SwiftSyntax

struct ConcurrencyModernizationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "concurrency_modernization",
        name: "Concurrency Modernization",
        description:
        "Flags GCD usage and legacy concurrency patterns that should use structured concurrency",
        kind: .concurrency,
        nonTriggeringExamples: [
            Example("Task { @MainActor in update() }"),
            Example("await withTaskGroup(of: Void.self) { }"),
        ],
        triggeringExamples: [
            Example("↓DispatchQueue.main.async { update() }"),
            Example("↓DispatchGroup()"),
            Example("func fetch(↓completion: @escaping (Result<Data, Error>) -> Void) {}"),
        ],
    )
}

extension ConcurrencyModernizationRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

extension ConcurrencyModernizationRule: OptInRule {}

extension ConcurrencyModernizationRule: AsyncEnrichableRule {
    func enrichAsync(
        file: SwiftLintFile,
        typeResolver: any TypeResolver,
    ) async -> [StyleViolation] {
        guard let filePath = file.path else { return [] }

        // Find DispatchQueue.*.async calls and verify via SourceKit
        let collector = DispatchQueueCallCollector(viewMode: .sourceAccurate)
        collector.walk(file.syntaxTree)

        var violations: [StyleViolation] = []

        for query in collector.queries {
            guard let resolved = await typeResolver.resolveType(
                inFile: filePath, offset: query.offset,
            ) else { continue }

            if resolved.moduleName == "Dispatch"
                || resolved.typeName.hasPrefix("Dispatch.DispatchQueue")
                || resolved.typeName == "DispatchQueue"
            {
                // Confirmed DispatchQueue — emit with high confidence
                violations.append(
                    StyleViolation(
                        ruleDescription: Self.description,
                        severity: configuration.severity,
                        location: Location(file: filePath, line: query.line, character: query.column),
                        reason: "DispatchQueue.async can be replaced with structured concurrency",
                        confidence: .high,
                        suggestion: "Use Task { @MainActor in ... } or async function",
                    ),
                )
            }
        }

        return violations
    }
}

private extension ConcurrencyModernizationRule {
    struct DispatchQueueQuery {
        let offset: Int
        let line: Int
        let column: Int
    }

    final class DispatchQueueCallCollector: SyntaxVisitor {
        var queries: [DispatchQueueQuery] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            let callee = node.calledExpression.trimmedDescription
            if ConcurrencyDetectionHelpers.isDispatchQueueAsync(callee) {
                let loc = node.startLocation(
                    converter: .init(fileName: "", tree: node.root),
                )
                queries.append(
                    DispatchQueueQuery(
                        offset: node.calledExpression.positionAfterSkippingLeadingTrivia.utf8Offset,
                        line: loc.line,
                        column: loc.column,
                    ),
                )
            }
            return .visitChildren
        }
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            for param in node.signature.parameterClause.parameters {
                if ConcurrencyDetectionHelpers.isCompletionHandlerParam(param) {
                    violations.append(
                        ReasonedRuleViolation(
                            position: node.positionAfterSkippingLeadingTrivia,
                            reason: "Function '\(node.name.text)' uses completion handler pattern",
                            severity: .warning,
                            confidence: .high,
                            suggestion: "Convert to async/await",
                        ),
                    )
                    break
                }
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            let callee = node.calledExpression.trimmedDescription

            if ConcurrencyDetectionHelpers.isDispatchQueueAsync(callee) {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "DispatchQueue.async can be replaced with structured concurrency",
                        severity: .warning,
                        confidence: .medium,
                        suggestion: "Use Task { @MainActor in ... } or async function",
                    ),
                )
            }

            if callee.contains("DispatchGroup") {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "DispatchGroup can be replaced with TaskGroup",
                        severity: .warning,
                        confidence: .medium,
                        suggestion: "Use withTaskGroup or withThrowingTaskGroup",
                    ),
                )
            }

            if callee.contains("NSLock()") || callee.contains("os_unfair_lock") {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Lock-based synchronization can be replaced with Mutex",
                        severity: .warning,
                        confidence: .medium,
                        suggestion: "Use Mutex<Value> for state protection",
                    ),
                )
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if ConcurrencyDetectionHelpers.hasUncheckedSendable(node.inheritanceClause) {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason:
                        "Class '\(node.name.text)' uses @unchecked Sendable — check if Mutex would enable proper Sendable",
                        severity: .warning,
                        confidence: .low,
                    ),
                )
            }
        }
    }
}
