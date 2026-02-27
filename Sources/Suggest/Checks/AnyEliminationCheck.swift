import SourceKitService
import SwiftSyntax

/// §1: Finds `Any`/`AnyObject` usage that erases type safety,
/// and similar functions that could be consolidated with generics.
///
/// When a `TypeResolver` is available, also detects type aliases
/// that resolve to `Any` (e.g. `typealias JSON = Any`).
public final class AnyEliminationCheck: BaseCheck {

    /// Tracks type annotations that aren't literally `Any` but might alias to it.
    private struct AliasQuery {
        let offset: Int
        let node: SyntaxProtocol
        let typeStr: String
    }

    private var aliasQueries: [AliasQuery] = []

    // MARK: - Any / AnyObject in type annotations

    override public func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
        checkForAny(in: node.type, at: node)
        return .visitChildren
    }

    override public func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
        checkForAny(in: node.type, at: node)
        return .visitChildren
    }

    // MARK: - [String: Any] dictionaries

    override public func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
        let key = node.key.trimmedDescription
        let value = node.value.trimmedDescription

        if key == "String" && (value == "Any" || value == "any Sendable") {
            addFinding(
                at: node,
                category: .anyElimination,
                severity: .medium,
                message: "[String: \(value)] dictionary should be a Codable struct",
                suggestion: "Define a struct with typed properties instead",
                confidence: .medium
            )
        }

        return .visitChildren
    }

    // MARK: - as? / as! casts from Any

    override public func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
        // Flag forced casts as higher severity
        if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
            addFinding(
                at: node,
                category: .anyElimination,
                severity: .medium,
                message: "Force cast 'as!' — trace back to where the type was erased",
                suggestion: "Use generics or a typed API to avoid the cast",
                confidence: .medium
            )
        }

        return .visitChildren
    }

    // MARK: - Helpers

    private func checkForAny(in type: TypeSyntax, at node: some SyntaxProtocol) {
        let typeStr = type.trimmedDescription

        if typeStr == "Any" || typeStr == "Any?" {
            addFinding(
                at: node,
                category: .anyElimination,
                severity: .medium,
                message: "Type 'Any' erases type safety",
                suggestion: "Use a specific type, protocol, or generic parameter",
                confidence: .medium
            )
        } else if typeStr == "AnyObject" || typeStr == "AnyObject?" {
            addFinding(
                at: node,
                category: .anyElimination,
                severity: .low,
                message: "Type 'AnyObject' — consider a specific class type or protocol",
                confidence: .low
            )
        } else if typeStr == "AnyHashable" {
            addFinding(
                at: node,
                category: .anyElimination,
                severity: .low,
                message: "Type 'AnyHashable' — check if all elements share a common concrete type",
                confidence: .low
            )
        } else if typeResolver?.isAvailable == true {
            // Queue for SourceKit resolution — might be a typealias for Any
            aliasQueries.append(AliasQuery(
                offset: type.positionAfterSkippingLeadingTrivia.utf8Offset,
                node: node,
                typeStr: typeStr
            ))
        }
    }

    override public func resolveTypeQueries() async {
        guard let resolver = typeResolver, !aliasQueries.isEmpty else { return }

        for query in aliasQueries {
            guard let resolved = await resolver.resolveType(inFile: filePath, offset: query.offset) else {
                continue
            }

            // Check if the resolved type is Any or AnyObject
            let resolvedName = resolved.typeName
            if resolvedName == "Any" || resolvedName == "Swift.Any" {
                let location = query.node.startLocation(converter: .init(
                    fileName: filePath,
                    tree: query.node.root
                ))
                findings.append(Finding(
                    category: .anyElimination,
                    severity: .medium,
                    file: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Type '\(query.typeStr)' resolves to 'Any' — type safety is erased",
                    suggestion: "Use a specific type, protocol, or generic parameter instead of the alias",
                    confidence: .high
                ))
            }
        }
    }
}
