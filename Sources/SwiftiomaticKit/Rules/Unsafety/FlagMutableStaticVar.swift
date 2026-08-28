import Foundation
import SwiftSyntax

/// Flag `static var` declarations with mutable storage. Global mutable state defeats Swift 6's
/// data-race safety; the fix is contextual (actor isolation, `Mutex`, `@TaskLocal`, or convert to a
/// computed `static var { ... }`), so this rule is flag-only.
///
/// Skips a declaration that a global actor already protects: the variable itself, or any enclosing
/// type or extension, carries an attribute such as `@MainActor` . A `nonisolated static var` opts
/// back out of that isolation, so it is still flagged.
///
/// Skips a `@TaskLocal` declaration. The property wrapper stores an immutable `let` and scopes
/// every write to one task, so the declaration is already data-race-safe. The message names
/// `@TaskLocal` as a fix, so flagging one is a contradiction.
///
/// Skips files under `Tests/` directories or named `*Tests.swift` — test fixtures often keep
/// mutable counters by design.
final class FlagMutableStaticVar: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard !context.fileURL.isTestFile else { return .visitChildren }
        guard node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }),
            node.bindingSpecifier.tokenKind == .keyword(.var) else { return .visitChildren }
        guard node.attributes.attribute(named: "TaskLocal") == nil else { return .visitChildren }
        guard !isGlobalActorIsolated(node) else { return .visitChildren }

        for binding in node.bindings where isStoredBinding(binding) {
            diagnose(.mutableStaticVar, on: node.bindingSpecifier)
            return .visitChildren
        }
        return .visitChildren
    }

    /// Reports whether a global actor protects this declaration.
    ///
    /// `nonisolated` on the variable itself drops the enclosing isolation, so the walk stops there
    /// and reports `false` . Otherwise the walk checks the variable's own attributes and then every
    /// enclosing declaration for a global-actor attribute.
    private func isGlobalActorIsolated(_ node: VariableDeclSyntax) -> Bool {
        if node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.nonisolated) }) {
            return false
        }
        var current: Syntax? = Syntax(node)

        while let candidate = current {
            if let withAttrs = candidate.asProtocol(WithAttributesSyntax.self),
               withAttrs.attributes.globalActorAttribute() != nil { return true }
            current = candidate.parent
        }
        return false
    }

    private func isStoredBinding(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = binding.accessorBlock else { return true }

        switch accessorBlock.accessors {
            case .getter: return false
            case let .accessors(list):
                // Stored property with willSet/didSet observers is still storage.
                for accessor in list {
                    switch accessor.accessorSpecifier.tokenKind {
                        case .keyword(.get),
                             .keyword(.set),
                             .keyword(._read),
                             .keyword(._modify),
                             .keyword(.unsafeAddress),
                             .keyword(.unsafeMutableAddress): return false
                        default: continue
                    }
                }
                return true
        }
    }
}

fileprivate extension Finding.Message {
    static let mutableStaticVar: Finding.Message =
        "'static var' with mutable storage is not data-race-safe — use an actor, 'Mutex', '@TaskLocal', or convert to a computed 'static var { ... }'"
}
