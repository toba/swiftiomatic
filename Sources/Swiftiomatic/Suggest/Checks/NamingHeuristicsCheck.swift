import SwiftSyntax

/// §6: Checks names against Swift API Design Guidelines.
///
/// When a `TypeResolver` is available, also checks variables without
/// explicit `: Bool` annotation but with an inferred Bool type.
public final class NamingHeuristicsCheck: BaseCheck {

    /// Bindings without explicit Bool annotation to check via expression types.
    private struct InferredBoolCandidate {
        let name: String
        let offset: Int
        let length: Int
        let node: SyntaxProtocol
    }

    private var inferredBoolCandidates: [InferredBoolCandidate] = []

    // MARK: - Protocol naming

    override public func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text

        // Check for -able suffix where -ing might be more appropriate
        // This is heuristic — flag for review, not definitive
        if name.hasSuffix("able") || name.hasSuffix("ible") {
            // Look at required methods — if they're actions the conformer performs,
            // -ing is more appropriate
            let methods = node.memberBlock.members.compactMap {
                $0.decl.as(FunctionDeclSyntax.self)
            }
            let hasActionVerbs = methods.contains { method in
                let name = method.name.text
                return name.hasPrefix("provide") || name.hasPrefix("supply")
                    || name.hasPrefix("create") || name.hasPrefix("generate")
                    || name.hasPrefix("load") || name.hasPrefix("fetch")
                    || name.hasPrefix("report") || name.hasPrefix("coordinate")
            }

            if hasActionVerbs {
                addFinding(
                    at: node,
                    category: .namingHeuristics,
                    severity: .low,
                    message: "Protocol '\(name)' uses -able suffix but conformers perform the action — consider -ing suffix",
                    suggestion: name.replacingSuffix("able", with: "ing")
                        ?? name.replacingSuffix("ible", with: "ing"),
                    confidence: .low
                )
            }
        }

        return .visitChildren
    }

    // MARK: - Boolean naming

    override public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            let name = pattern.identifier.text

            // Check if it's a Bool type
            if let typeAnnotation = binding.typeAnnotation,
               typeAnnotation.type.trimmedDescription == "Bool"
            {
                checkBoolNaming(name: name, node: binding)
            } else if binding.typeAnnotation == nil,
                      binding.initializer != nil,
                      typeResolver?.isAvailable == true
            {
                // No explicit type annotation but has initializer — might be inferred Bool
                let initExpr = binding.initializer!.value
                inferredBoolCandidates.append(InferredBoolCandidate(
                    name: name,
                    offset: initExpr.positionAfterSkippingLeadingTrivia.utf8Offset,
                    length: initExpr.trimmedLength.utf8Length,
                    node: binding
                ))
            }
        }

        return .visitChildren
    }

    private func checkBoolNaming(name: String, node: some SyntaxProtocol) {
        let assertionPrefixes = [
            "is", "has", "can", "should", "will", "did", "was",
            "needs", "allows", "requires", "supports", "includes",
            "contains", "enables",
        ]
        let startsWithAssertion = assertionPrefixes.contains { prefix in
            name.hasPrefix(prefix) && name.count > prefix.count
                && name[name.index(name.startIndex, offsetBy: prefix.count)].isUppercase
        }

        if !startsWithAssertion && !name.hasPrefix("_") {
            addFinding(
                at: node,
                category: .namingHeuristics,
                severity: .low,
                message: "Bool property '\(name)' doesn't read as an assertion",
                suggestion: "Consider a name like 'is\(name.capitalized)' or 'has\(name.capitalized)'",
                confidence: .low
            )
        }
    }

    override public func resolveTypeQueries() async {
        guard let resolver = typeResolver, !inferredBoolCandidates.isEmpty else { return }

        let exprTypes = await resolver.expressionTypes(inFile: filePath)
        guard !exprTypes.isEmpty else { return }

        for candidate in inferredBoolCandidates {
            // Find matching expression type by offset
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

    override public func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text

        // Static methods that return Self or the enclosing type should use make- prefix
        if node.modifiers.contains(where: { $0.name.text == "static" }) {
            let hasCreatePrefix = name.hasPrefix("create") || name.hasPrefix("new")
                || name.hasPrefix("build")
            if hasCreatePrefix {
                let stripped: String
                if name.hasPrefix("create") {
                    stripped = String(name.dropFirst(6))
                } else if name.hasPrefix("new") {
                    stripped = String(name.dropFirst(3))
                } else {
                    stripped = String(name.dropFirst(5))
                }
                addFinding(
                    at: node,
                    category: .namingHeuristics,
                    severity: .low,
                    message: "Factory method '\(name)' should use 'make' prefix per Swift API Design Guidelines",
                    suggestion: "make\(stripped)",
                    confidence: .medium
                )
            }
        }

        return .visitChildren
    }
}

extension String {
    func replacingSuffix(_ suffix: String, with replacement: String) -> String? {
        guard hasSuffix(suffix) else { return nil }
        return String(dropLast(suffix.count)) + replacement
    }
}
