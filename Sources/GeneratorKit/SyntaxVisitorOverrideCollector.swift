import Foundation
import SwiftSyntax

/// Scans `TokenStream+*.swift` extension files to discover visit methods that need
/// forwarding stubs in the generated `TokenStream` subclass.
package final class SyntaxVisitorOverrideCollector {
    var overrides = [DetectedOverride]()

    package init() {}

    /// Scans all `TokenStream+*.swift` files in the given directory for visit methods.
    package func collect(from directory: URL) throws {
        try enumerateSwiftStatements(
            in: directory,
            filter: { $0.hasPrefix("TokenStream+") }
        ) { statement in
            collectOverrides(from: statement)
        }
        overrides.sort()
    }

    /// Scans all Swift files in the given directory for `extension TokenStream`
    /// visit methods. Unlike `collect(from:)`, this has no filename filter.
    package func collectExtensions(from directory: URL) throws {
        try enumerateSwiftStatements(in: directory) { statement in
            collectOverrides(from: statement)
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
        // Visitor methods always have a single parameter whose type ends in "Syntax".
        let paramLabel = param.secondName?.text ?? param.firstName.text

        return DetectedOverride(
            isPost: isPost,
            methodName: name,
            paramLabel: paramLabel,
            paramType: paramTypeName,
        )
    }
}

// MARK: - Support

extension SyntaxVisitorOverrideCollector {
    /// A single visit or visitPost method found in a TSC extension.
    struct DetectedOverride: Comparable {
        /// Whether this is a `visitPost` override (void return) vs a `visit` override.
        let isPost: Bool

        /// The method name in the extension (e.g. "visitAccessorDeclList" or "visitPostFunctionCallExpr").
        let methodName: String

        /// The parameter label ("node" or "token").
        let paramLabel: String

        /// The parameter type (e.g. "AccessorDeclListSyntax" or "TokenSyntax").
        let paramType: String

        static func < (lhs: DetectedOverride, rhs: DetectedOverride) -> Bool {
            if lhs.isPost != rhs.isPost { return !lhs.isPost }
            return lhs.paramType < rhs.paramType
        }
    }
}
