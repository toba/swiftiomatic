import SwiftSyntax

/// In protocol property requirements, accessors must be declared in `get set`
/// order. The reverse — `set get` — is legal Swift but inconsistent with the
/// canonical form used throughout the standard library and the Swift book.
///
/// Lint: A finding is raised when a protocol property's accessor block lists
///       `set` before `get`.
///
/// Rewrite: The accessors are reordered to `get set`.
final class ProtocolAccessorOrder: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var defaultValue: BasicRuleValue {
        BasicRuleValue(rewrite: false, lint: .warn)
    }

    override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        return Self.transform(visited, parent: parent, context: context)
    }

    static func transform(
        _ node: AccessorBlockSyntax,
        parent: Syntax?,
        context: Context
    ) -> AccessorBlockSyntax {
        guard hasViolation(node), inProtocolDecl(parent: parent) else { return node }

        Self.diagnose(.swapAccessorOrder, on: node.accessors, context: context)

        guard case .accessors(let accessors) = node.accessors else { return node }
        let reversed = AccessorDeclListSyntax(Array(accessors.reversed()))
        var result = node
        result.accessors = .accessors(reversed)
        return result
    }

    private static func hasViolation(_ node: AccessorBlockSyntax) -> Bool {
        guard case .accessors(let accessors) = node.accessors else { return false }
        return accessors.count == 2
            && accessors.allSatisfy({ $0.body == nil })
            && accessors.first?.accessorSpecifier.tokenKind == .keyword(.set)
    }

    private static func inProtocolDecl(parent: Syntax?) -> Bool {
        var current: Syntax? = parent
        while let p = current {
            if p.is(ProtocolDeclSyntax.self) { return true }
            // Stop at the nearest non-protocol type declaration to avoid false positives
            // for properties inside nested non-protocol types.
            if p.is(StructDeclSyntax.self)
                || p.is(ClassDeclSyntax.self)
                || p.is(EnumDeclSyntax.self)
                || p.is(ActorDeclSyntax.self)
                || p.is(ExtensionDeclSyntax.self)
            {
                return false
            }
            current = p.parent
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let swapAccessorOrder: Finding.Message =
        "swap accessor order to 'get set'"
}
