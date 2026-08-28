import Foundation
import SwiftSyntax

/// Scans Swift files for `extension TokenStream` visit methods that need forwarding stubs in the
/// generated `TokenStream` subclass.
package final class TokenStreamExtensionCollector {
    var overrides = [DetectedOverride]()

    package init() {}

    /// Scans a directory for `extension TokenStream` visit methods, appending to any already found.
    ///
    /// - Parameters:
    ///   - directory: The directory to scan.
    ///   - filter: Optional predicate on the file base name. Pass
    ///     `{ $0.hasPrefix("TokenStream+") }` for the token folder, and omit it for a tree where
    ///     the extensions sit beside other code.
    package func collect(
        from directory: URL,
        filter: (@Sendable (String) -> Bool)? = nil
    ) async throws {
        try await enumerateSwiftStatements(in: directory, filter: filter) { statement in
            self.collectOverrides(from: statement)
        }
        overrides.sort()
    }

    private func collectOverrides(from statement: CodeBlockItemSyntax) {
        guard let extensionDecl = statement.item.as(ExtensionDeclSyntax.self),
            extensionDecl.extendedType.as(IdentifierTypeSyntax.self)?.name.text == "TokenStream"
        else { return }

        for member in extensionDecl.memberBlock.members {
            if let stub = detectOverride(from: member) { overrides.append(stub) }
        }
    }

    private func detectOverride(from member: MemberBlockItemSyntax) -> DetectedOverride? {
        guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { return nil }

        let name = funcDecl.name.text
        guard name.hasPrefix("visit") else { return nil }

        let params = funcDecl.signature.parameterClause.parameters
        guard let param = params.firstAndOnly else { return nil }

        guard let paramType = param.type.as(IdentifierTypeSyntax.self) else { return nil }
        let paramTypeName = paramType.name.text
        guard paramTypeName.hasSuffix("Syntax") else { return nil }

        // Distinguish visitPost (void return) from visit (returns SyntaxVisitorContinueKind).
        let hasReturn = funcDecl.signature.returnClause != nil
        let isPost = !hasReturn

        // Skip helper methods that happen to start with "visit" but aren't visitor overrides.
        // Visitor methods always have a single parameter whose type ends in "Syntax". Fall back to
        // "node" when the source uses the anonymous form `_: SomeSyntax` — the forwarding stub
        // needs a real identifier to pass through.
        let rawLabel = param.secondName?.text ?? param.firstName.text
        let paramLabel = rawLabel == "_" ? "node" : rawLabel

        return DetectedOverride(
            isPost: isPost,
            methodName: name,
            paramLabel: paramLabel,
            paramType: paramTypeName,
        )
    }
}

// MARK: - Support

extension TokenStreamExtensionCollector {
    /// A single visit or visitPost method found in a TokenStream extension.
    struct DetectedOverride: Comparable {
        /// Whether this is a `visitPost` override (void return) vs a `visit` override.
        let isPost: Bool

        /// The method name in the extension (e.g. "visitAccessorDeclList" or
        /// "visitPostFunctionCallExpr").
        let methodName: String

        /// The parameter label ("node" or "token").
        let paramLabel: String

        /// The parameter type (e.g. "AccessorDeclListSyntax" or "TokenSyntax").
        let paramType: String

        static func < (lhs: DetectedOverride, rhs: DetectedOverride) -> Bool {
            lhs.isPost != rhs.isPost ? !lhs.isPost : lhs.paramType < rhs.paramType
        }
    }
}
