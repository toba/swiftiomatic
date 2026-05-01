import SwiftSyntax

extension InheritanceClauseSyntax {
    /// Returns a copy with the inherited type matching `typeName` removed, or `nil` if the clause
    /// becomes empty (the caller should set `inheritanceClause = nil` ).
    ///
    /// Matching uses `trimmedDescription` on the type, so both simple names ( `Sendable` ) and
    /// qualified names ( `Swift.Sendable` ) work.
    ///
    /// Comma handling:
    /// - Removing the only item → returns `nil`
    /// - Removing a non-last item → its trailing comma is dropped with it
    /// - Removing the last item → the preceding item's trailing comma is removed
    func removing(named typeName: String) -> InheritanceClauseSyntax? {
        var items = Array(inheritedTypes)
        guard let index = items.firstIndex(where: { $0.type.trimmedDescription == typeName }) else {
            return self
        }

        let removed = items.remove(at: index)

        guard !items.isEmpty else { return nil }

        // Fix trailing comma: the new last item must not have one.
        let lastIndex = items.count - 1
        if items[lastIndex].trailingComma != nil {
            items[lastIndex] = items[lastIndex].with(\.trailingComma, nil)
        }

        // Transfer the removed item's trailing trivia to the new last item so that trivia following
        // the inheritance clause (e.g. space before `{` ) is preserved.
        items[lastIndex] = items[lastIndex].with(\.trailingTrivia, removed.trailingTrivia)

        // Transfer removed item's leading trivia to the new first item if we removed index 0.
        if index == 0 {
            items[0] = items[0].with(\.leadingTrivia, inheritedTypes.first!.leadingTrivia)
        }

        return with(\.inheritedTypes, InheritedTypeListSyntax(items))
    }

    /// Returns `true` if the clause contains an inherited type matching `typeName` .
    func contains(named typeName: String) -> Bool {
        inheritedTypes.contains { $0.type.trimmedDescription == typeName }
    }

    /// Returns the `InheritedTypeSyntax` matching `typeName` , or `nil` .
    func inherited(named typeName: String) -> InheritedTypeSyntax? {
        inheritedTypes.first { $0.type.trimmedDescription == typeName }
    }
}
