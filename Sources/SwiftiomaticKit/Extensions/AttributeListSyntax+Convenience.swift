import SwiftSyntax

extension AttributeListSyntax {
    /// Returns the first `AttributeSyntax` whose simple name matches `name`, or `nil`.
    ///
    /// Only plain `@Name` attributes are matched. `@Module.Name` and `#if`-wrapped attributes
    /// are ignored. Attributes with arguments (e.g. `@objc(selector:)`) ARE returned — the caller
    /// decides whether arguments disqualify the match.
    func attribute(named name: String) -> AttributeSyntax? {
        for element in self {
            guard case .attribute(let attr) = element,
                let ident = attr.attributeName.as(IdentifierTypeSyntax.self),
                ident.name.text == name
            else {
                continue
            }
            return attr
        }
        return nil
    }

    /// Returns a copy with the first attribute matching `name` removed.
    ///
    /// Trivia from the removed attribute's leading position is transferred to the next kept
    /// element. When the list becomes empty (the removed attribute was the only one), the caller
    /// must transfer the attribute's leading trivia to the declaration keyword or next modifier.
    /// This mirrors `DeclModifierListSyntax.remove(anyOf:)` — see `RedundantAccessControl` for the
    /// modifier pattern and `RedundantViewBuilder` for the attribute pattern.
    func removing(named name: String) -> AttributeListSyntax {
        guard let target = attribute(named: name) else { return self }

        var result = [Element]()
        var removedLeadingTrivia: Trivia?

        for element in self {
            if case .attribute(let attr) = element, attr.id == target.id {
                removedLeadingTrivia = attr.leadingTrivia
                continue
            }

            var kept = element
            // Transfer the removed attribute's leading trivia to the next kept element.
            if let trivia = removedLeadingTrivia {
                kept = kept.with(\.leadingTrivia, trivia)
                removedLeadingTrivia = nil
            }
            result.append(kept)
        }

        return AttributeListSyntax(result)
    }

    /// Removes the first attribute matching `name` in place.
    ///
    /// See ``removing(named:)`` for trivia handling details.
    mutating func remove(named name: String) {
        self = removing(named: name)
    }
}
