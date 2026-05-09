import Foundation
import SwiftSyntax

/// Flag `static var` declarations with mutable storage. Global mutable state defeats Swift 6's
/// data-race safety; the fix is contextual (actor isolation, `Mutex`, `@TaskLocal`, or convert
/// to a computed `static var { ... }`), so this rule is flag-only.
///
/// Skips files under `Tests/` directories or named `*Tests.swift` — test fixtures often
/// keep mutable counters by design.
final class FlagMutableStaticVar: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard !isTestFile(context.fileURL) else { return .visitChildren }
        guard node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }),
              node.bindingSpecifier.tokenKind == .keyword(.var) else { return .visitChildren }

        for binding in node.bindings where isStoredBinding(binding) {
            diagnose(.mutableStaticVar, on: node.bindingSpecifier)
            return .visitChildren
        }
        return .visitChildren
    }

    private func isStoredBinding(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = binding.accessorBlock else { return true }
        switch accessorBlock.accessors {
            case .getter: return false
            case let .accessors(list):
                // Stored property with willSet/didSet observers is still storage.
                for accessor in list {
                    switch accessor.accessorSpecifier.tokenKind {
                        case .keyword(.get), .keyword(.set), .keyword(._read), .keyword(._modify),
                             .keyword(.unsafeAddress), .keyword(.unsafeMutableAddress):
                            return false
                        default: continue
                    }
                }
                return true
        }
    }

    private func isTestFile(_ url: URL) -> Bool {
        let path = url.path
        if path.contains("/Tests/") { return true }
        let lastComponent = url.lastPathComponent
        return lastComponent.hasSuffix("Tests.swift")
    }
}

fileprivate extension Finding.Message {
    static let mutableStaticVar: Finding.Message =
        "'static var' with mutable storage is not data-race-safe — use an actor, 'Mutex', '@TaskLocal', or convert to a computed 'static var { ... }'"
}
