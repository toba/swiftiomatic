import SwiftSyntax

/// Optional collections like `[T]?` , `[K: V]?` , and `Set<T>?` add a state ( `nil` ) that is
/// rarely distinguishable from "empty". Prefer the non-optional collection and use `isEmpty` to
/// check for absence.
///
/// Lint: A warning is raised for any `OptionalTypeSyntax` whose wrapped type is an array,
/// dictionary, or named `Array` / `Dictionary` / `Set` .
final class NoOptionalCollection: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .types }

    override func visit(_ node: OptionalTypeSyntax) -> SyntaxVisitorContinueKind {
        if node.wrappedType.isCollectionType { diagnose(.noOptionalCollection, on: node) }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let noOptionalCollection: Finding.Message =
        "prefer a non-optional collection (use 'isEmpty' to check for absence) over an optional one"
}

fileprivate extension TypeSyntax {
    var isCollectionType: Bool {
        if `is`(ArrayTypeSyntax.self) || `is`(DictionaryTypeSyntax.self) { return true }
        if let id = self.as(IdentifierTypeSyntax.self) {
            return ["Array", "Dictionary", "Set"].contains(id.name.text)
        }
        return false
    }
}
