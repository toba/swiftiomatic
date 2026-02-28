/// The visibility of a declaration
enum Visibility: String, CaseIterable, Comparable {
    case open
    case `public`
    case package
    case `internal`
    case `fileprivate`
    case `private`

    static func < (lhs: Visibility, rhs: Visibility) -> Bool {
        allCases.firstIndex(of: lhs)! > allCases.firstIndex(of: rhs)!
    }
}

extension Declaration {
    /// The explicit `Visibility` of this `Declaration`
    func visibility() -> Visibility? {
        switch kind {
            case .declaration, .type:
                return formatter.declarationVisibility(keywordIndex: keywordIndex)

            case let .conditionalCompilation(conditionalCompilation):
                // Conditional compilation blocks themselves don't have a category or visbility-level,
                // but we still have to assign them a category for the sorting algorithm to function.
                // A reasonable heuristic here is to simply use the category of the first declaration
                // inside the conditional compilation block.
                return conditionalCompilation.body.first?.visibility()
        }
    }

    /// Adds the given visibility keyword to the given declaration,
    /// replacing any existing visibility keyword.
    func addVisibility(_ visibilityKeyword: Visibility) {
        formatter.addDeclarationVisibility(visibilityKeyword, declarationKeywordIndex: keywordIndex)
    }

    /// Removes the given visibility keyword from the given declaration
    func removeVisibility(_ visibilityKeyword: Visibility) {
        formatter.removeDeclarationVisibility(
            visibilityKeyword,
            declarationKeywordIndex: keywordIndex,
        )
    }
}
