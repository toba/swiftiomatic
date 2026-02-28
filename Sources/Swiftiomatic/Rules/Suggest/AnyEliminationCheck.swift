import SwiftSyntax

/// §1: Finds `Any`/`AnyObject` usage that erases type safety,
/// and similar functions that could be consolidated with generics.
///
/// When a `TypeResolver` is available, also detects type aliases
/// that resolve to `Any` (e.g. `typealias JSON = Any`).
final class AnyEliminationCheck: BaseCheck {
    /// Tracks type annotations that aren't literally `Any` but might alias to it.
    private struct AliasQuery {
        let offset: Int
        let node: SyntaxProtocol
        let typeStr: String
    }

    private var aliasQueries: [AliasQuery] = []

    // MARK: - Any / AnyObject in type annotations

    override func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
        checkForAny(in: node.type, at: node)
        return .visitChildren
    }

    override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
        checkForAny(in: node.type, at: node)
        return .visitChildren
    }

    // MARK: - [String: Any] dictionaries

    override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
        let key = node.key.trimmedDescription
        let value = node.value.trimmedDescription

        if key == "String", value == "Any" || value == "any Sendable" {
            addFinding(
                at: node,
                category: .anyElimination,
                severity: .medium,
                message: "[String: \(value)] dictionary should be a Codable struct",
                suggestion: "Define a struct with typed properties instead",
                confidence: .medium,
            )
        }

        return .visitChildren
    }

    // MARK: - as? / as! casts from Any

    override func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
        if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
            addFinding(
                at: node,
                category: .anyElimination,
                severity: .medium,
                message: "Force cast 'as!' — trace back to where the type was erased",
                suggestion: "Use generics or a typed API to avoid the cast",
                confidence: .medium,
            )
        }

        return .visitChildren
    }

    // MARK: - Helpers

    private func checkForAny(in type: TypeSyntax, at node: some SyntaxProtocol) {
        let typeStr = type.trimmedDescription

        if let match = AnyTypeHelpers.classifyAnyType(typeStr) {
            addFinding(
                at: node,
                category: .anyElimination,
                severity: match == .any ? .medium : .low,
                message: match.message,
                suggestion: match.suggestion,
                confidence: match == .any ? .medium : .low,
            )
        } else if typeResolver?.isAvailable == true {
            aliasQueries.append(
                AliasQuery(
                    offset: type.positionAfterSkippingLeadingTrivia.utf8Offset,
                    node: node,
                    typeStr: typeStr,
                ),
            )
        }
    }

    override func resolveTypeQueries() async {
        guard let resolver = typeResolver, !aliasQueries.isEmpty else { return }

        for query in aliasQueries {
            guard let resolved = await resolver.resolveType(inFile: filePath, offset: query.offset)
            else {
                continue
            }

            let resolvedName = resolved.typeName
            if resolvedName == "Any" || resolvedName == "Swift.Any" {
                let location = query.node.startLocation(
                    converter: .init(
                        fileName: filePath,
                        tree: query.node.root,
                    ),
                )
                findings.append(
                    Finding(
                        category: .anyElimination,
                        severity: .medium,
                        file: filePath,
                        line: location.line,
                        column: location.column,
                        message: "Type '\(query.typeStr)' resolves to 'Any' — type safety is erased",
                        suggestion: "Use a specific type, protocol, or generic parameter instead of the alias",
                        confidence: .high,
                    ),
                )
            }
        }
    }
}
