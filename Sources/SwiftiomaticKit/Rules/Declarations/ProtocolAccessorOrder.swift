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
        guard hasViolation(node), inProtocolDecl(node) else {
            return super.visit(node)
        }

        diagnose(.swapAccessorOrder, on: node.accessors)

        guard case .accessors(let accessors) = node.accessors else {
            return super.visit(node)
        }
        let reversed = AccessorDeclListSyntax(Array(accessors.reversed()))
        var result = node
        result.accessors = .accessors(reversed)
        return super.visit(result)
    }

    private func hasViolation(_ node: AccessorBlockSyntax) -> Bool {
        guard case .accessors(let accessors) = node.accessors else { return false }
        return accessors.count == 2
            && accessors.allSatisfy({ $0.body == nil })
            && accessors.first?.accessorSpecifier.tokenKind == .keyword(.set)
    }

    private func inProtocolDecl(_ node: AccessorBlockSyntax) -> Bool {
        var current: Syntax? = node.parent
        while let parent = current {
            if parent.is(ProtocolDeclSyntax.self) { return true }
            // Stop at the nearest non-protocol type declaration to avoid false positives
            // for properties inside nested non-protocol types.
            if parent.is(StructDeclSyntax.self)
                || parent.is(ClassDeclSyntax.self)
                || parent.is(EnumDeclSyntax.self)
                || parent.is(ActorDeclSyntax.self)
                || parent.is(ExtensionDeclSyntax.self)
            {
                return false
            }
            current = parent.parent
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let swapAccessorOrder: Finding.Message =
        "swap accessor order to 'get set'"
}
