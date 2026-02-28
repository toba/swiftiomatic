import Foundation
import SwiftSyntax

/// §6: Checks names against Swift API Design Guidelines.
///
/// When a `TypeResolver` is available, also checks variables without
/// explicit `: Bool` annotation but with an inferred Bool type.
final class NamingHeuristicsCheck: BaseCheck {
    /// Bindings without explicit Bool annotation to check via expression types.
    private struct InferredBoolCandidate {
        let name: String
        let offset: Int
        let length: Int
        let node: SyntaxProtocol
    }

    private var inferredBoolCandidates: [InferredBoolCandidate] = []

    // MARK: - Protocol naming

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text

        if name.hasSuffix("able") || name.hasSuffix("ible") {
            let methods = node.memberBlock.members.compactMap {
                $0.decl.as(FunctionDeclSyntax.self)
            }
            let hasActionVerbs = methods.contains { method in
                let n = method.name.text
                return NamingHelpers.actionVerbPrefixes.contains { n.hasPrefix($0) }
            }

            if hasActionVerbs {
                addFinding(
                    at: node,
                    category: .namingHeuristics,
                    severity: .low,
                    message:
                    "Protocol '\(name)' uses -able suffix but conformers perform the action — consider -ing suffix",
                    suggestion: name.replacingSuffix("able", with: "ing")
                        ?? name.replacingSuffix("ible", with: "ing"),
                    confidence: .low,
                )
            }
        }

        return .visitChildren
    }

    // MARK: - Boolean naming

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            let name = pattern.identifier.text

            if let typeAnnotation = binding.typeAnnotation,
               typeAnnotation.type.trimmedDescription == "Bool"
            {
                checkBoolNaming(name: name, node: binding)
            } else if binding.typeAnnotation == nil,
                      binding.initializer != nil,
                      typeResolver?.isAvailable == true
            {
                let initExpr = binding.initializer!.value
                inferredBoolCandidates.append(
                    InferredBoolCandidate(
                        name: name,
                        offset: initExpr.positionAfterSkippingLeadingTrivia.utf8Offset,
                        length: initExpr.trimmedLength.utf8Length,
                        node: binding,
                    ),
                )
            }
        }

        return .visitChildren
    }

    private func checkBoolNaming(name: String, node: some SyntaxProtocol) {
        if !NamingHelpers.isAssertionNamed(name), !name.hasPrefix("_") {
            addFinding(
                at: node,
                category: .namingHeuristics,
                severity: .low,
                message: "Bool property '\(name)' doesn't read as an assertion",
                suggestion: "Consider a name like 'is\(name.capitalized)' or 'has\(name.capitalized)'",
                confidence: .low,
            )
        }
    }

    override func resolveTypeQueries() async {
        guard let resolver = typeResolver, !inferredBoolCandidates.isEmpty else { return }

        let exprTypes = await resolver.expressionTypes(inFile: filePath)
        guard !exprTypes.isEmpty else { return }

        for candidate in inferredBoolCandidates {
            let isBool = exprTypes.contains { info in
                info.offset == candidate.offset
                    && (info.typeName == "Bool" || info.typeName == "Swift.Bool")
            }
            if isBool {
                checkBoolNaming(name: candidate.name, node: candidate.node)
            }
        }
    }

    // MARK: - Factory methods

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text

        if node.modifiers.contains(where: { $0.name.text == "static" }) {
            if let suggestion = NamingHelpers.factoryMethodSuggestion(for: name) {
                addFinding(
                    at: node,
                    category: .namingHeuristics,
                    severity: .low,
                    message:
                    "Factory method '\(name)' should use 'make' prefix per Swift API Design Guidelines",
                    suggestion: suggestion,
                    confidence: .medium,
                )
            }
        }

        return .visitChildren
    }
}
