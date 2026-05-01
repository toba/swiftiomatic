import SwiftSyntax

/// Sort protocol composition typealiases alphabetically.
///
/// When a typealias combines multiple protocols with `&` (e.g. `typealias Deps = Foo & Bar & Baz`
/// ), the types are sorted lexicographically. Duplicate types are removed. The `any` keyword, if
/// present, is preserved at the beginning.
///
/// Lint: If the composition types are not sorted, a lint warning is raised.
///
/// Rewrite: The types are reordered alphabetically and duplicates are removed.
final class SortTypeAliases: StructuralFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .sort }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        let initializer = node.initializer

        // Unwrap `any` wrapper if present
        var typeNode = initializer.value
        var isWrappedInAny = false

        if let someOrAny = typeNode.as(SomeOrAnyTypeSyntax.self),
           someOrAny.someOrAnySpecifier.tokenKind == .keyword(.any)
        {
            isWrappedInAny = true
            typeNode = someOrAny.constraint
        }

        guard let composition = typeNode.as(CompositionTypeSyntax.self) else {
            return DeclSyntax(node)
        }
        let elements = Array(composition.elements)
        guard elements.count > 1 else { return DeclSyntax(node) }

        // Sort by type name (strip `any` prefix for comparison since it applies to entire
        // composition)
        let sorted = elements.sorted { lhs, rhs in
            let lhsName = lhs.type.trimmedDescription
            let rhsName = rhs.type.trimmedDescription
            return lhsName.lexicographicallyPrecedes(rhsName)
        }

        // Remove duplicates
        var seen = Set<String>()
        var deduped = [CompositionTypeElementSyntax]()

        for elem in sorted {
            let key = elem.type.trimmedDescription
            if seen.insert(key).inserted { deduped.append(elem) }
        }

        // Check if already sorted with no duplicates
        if deduped.count == elements.count {
            let originalNames = elements.map(\.type.trimmedDescription)
            let sortedNames = deduped.map(\.type.trimmedDescription)
            guard originalNames != sortedNames else { return DeclSyntax(node) }
        }

        diagnose(.sortTypealiases, on: node.typealiasKeyword)

        // Rebuild preserving positional trivia structure. Each position has a "slot" with trivia
        // from the original element at that index.
        var newElements = [CompositionTypeElementSyntax]()

        for (i, sortedElem) in deduped.enumerated() {
            // Use the sorted element's type content with the original position's trivia structure.
            // For the last element, use the original last element's trailing trivia to avoid
            // inheriting a trailing space from a non-last position.
            var newType = sortedElem.type

            if i < elements.count {
                newType.leadingTrivia = elements[i].type.leadingTrivia
                newType.trailingTrivia = i == deduped.count - 1
                    ? elements[elements.count - 1].type.trailingTrivia
                    : elements[i].type.trailingTrivia
            }

            let ampersand: TokenSyntax?

            if i < deduped.count - 1 {
                // Non-last: need ampersand
                if i < elements.count, let origAmp = elements[i].ampersand {
                    ampersand = origAmp
                } else {
                    ampersand = .binaryOperator("&", leadingTrivia: .space, trailingTrivia: .space)
                }
            } else {
                ampersand = nil
            }

            newElements.append(
                CompositionTypeElementSyntax(
                    type: TypeSyntax(newType),
                    ampersand: ampersand
                ))
        }

        var newComposition = composition
        newComposition.elements = CompositionTypeElementListSyntax(newElements)

        var result = node

        if isWrappedInAny {
            var wrapper = initializer.value.cast(SomeOrAnyTypeSyntax.self)
            wrapper.constraint = TypeSyntax(newComposition)
            result.initializer.value = TypeSyntax(wrapper)
        } else {
            result.initializer.value = TypeSyntax(newComposition)
        }
        return DeclSyntax(result)
    }
}

fileprivate extension Finding.Message {
    static let sortTypealiases: Finding.Message = "sort protocol composition types alphabetically"
}
