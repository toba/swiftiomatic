import SwiftSyntax

/// Properties whose name ends in `delegate` should be declared `weak` to avoid retain cycles.
///
/// This rule fires only on class instance properties. Local variables, struct/enum members,
/// computed properties, protocol requirements, and properties marked with one of the SwiftUI
/// adaptor attributes (`@UIApplicationDelegateAdaptor`, `@NSApplicationDelegateAdaptor`,
/// `@WKExtensionDelegateAdaptor`) are excluded. Properties already marked `weak` or `unowned`
/// pass.
///
/// Lint: A class instance property named `*delegate` without a `weak`/`unowned` modifier yields
/// a warning.
final class WeakDelegates: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {

    /// Skip protocol bodies — properties declared in protocols cannot be `weak`.
    override func visit(_: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.hasDelegateSuffix,
            !node.hasWeakOrUnownedModifier,
            !node.hasComputedBody,
            !node.hasIgnoredAdaptorAttribute,
            node.isInClassBody
        else {
            return .visitChildren
        }

        diagnose(.weakDelegate, on: node.bindingSpecifier)
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let weakDelegate: Finding.Message =
        "declare 'delegate' property as 'weak' to avoid retain cycles"
}

extension VariableDeclSyntax {
    fileprivate var hasDelegateSuffix: Bool {
        bindings.allSatisfy { binding in
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                return false
            }
            return pattern.identifier.text.lowercased().hasSuffix("delegate")
        }
    }

    fileprivate var hasWeakOrUnownedModifier: Bool {
        modifiers.contains { modifier in
            switch modifier.name.tokenKind {
            case .keyword(.weak), .keyword(.unowned): true
            default: false
            }
        }
    }

    fileprivate var hasComputedBody: Bool {
        bindings.contains { binding in
            guard let accessorBlock = binding.accessorBlock else { return false }
            switch accessorBlock.accessors {
            case .getter:
                return true
            case .accessors(let list):
                return list.contains { $0.accessorSpecifier.tokenKind == .keyword(.get) }
            }
        }
    }

    fileprivate var hasIgnoredAdaptorAttribute: Bool {
        let ignored: Set<String> = [
            "UIApplicationDelegateAdaptor",
            "NSApplicationDelegateAdaptor",
            "WKExtensionDelegateAdaptor",
        ]
        return attributes.contains { element in
            guard let attr = element.as(AttributeSyntax.self),
                let name = attr.attributeName.as(IdentifierTypeSyntax.self)
            else { return false }
            return ignored.contains(name.name.text)
        }
    }

    /// True if this declaration appears as a member of a class body (directly or via an
    /// extension on a class). Returns false for local variables, struct/enum/actor members,
    /// and protocol requirements.
    fileprivate var isInClassBody: Bool {
        var node: Syntax? = parent
        while let current = node {
            if current.is(ClassDeclSyntax.self) {
                return true
            }
            // If we hit any non-class declaration boundary, this isn't a class member.
            if current.is(StructDeclSyntax.self)
                || current.is(EnumDeclSyntax.self)
                || current.is(ActorDeclSyntax.self)
                || current.is(ProtocolDeclSyntax.self)
                || current.is(FunctionDeclSyntax.self)
                || current.is(InitializerDeclSyntax.self)
                || current.is(DeinitializerDeclSyntax.self)
                || current.is(AccessorDeclSyntax.self)
                || current.is(AccessorBlockSyntax.self)
                || current.is(ClosureExprSyntax.self)
                || current.is(ExtensionDeclSyntax.self)
            {
                return false
            }
            node = current.parent
        }
        return false
    }
}
