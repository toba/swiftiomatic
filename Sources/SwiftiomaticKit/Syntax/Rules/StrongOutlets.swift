import SwiftSyntax

/// Remove `weak` from `@IBOutlet` properties.
///
/// As per Apple's recommendation, `@IBOutlet` properties should be strong. The `weak`
/// modifier is preserved for delegate and data source outlets since those are typically
/// owned elsewhere.
///
/// Lint: An `@IBOutlet` property with `weak` raises a warning.
///
/// Format: The `weak` modifier is removed.
final class StrongOutlets: RewriteSyntaxRule<BasicRuleValue> {

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        // Must have @IBOutlet attribute
        guard hasIBOutletAttribute(node) else { return DeclSyntax(node) }

        // Must have `weak` modifier
        guard node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.weak) }) else {
            return DeclSyntax(node)
        }

        // Preserve weak for delegate and data source outlets
        if let name = node.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        {
            let lowercased = name.lowercased()
            if lowercased.hasSuffix("delegate") || lowercased.hasSuffix("datasource") {
                return DeclSyntax(node)
            }
        }

        diagnose(
            .removeWeakFromOutlet,
            on: node.modifiers.first(where: {
                $0.name.tokenKind == .keyword(.weak)
            })!.name
        )

        var result = node
        let weakIsFirst = result.modifiers.first?.name.tokenKind == .keyword(.weak)
        let savedLeadingTrivia =
            weakIsFirst
            ? result.modifiers.first!.leadingTrivia
            : Trivia()

        result.modifiers.remove(anyOf: [.weak])

        // Only transfer trivia when weak was the first modifier
        if weakIsFirst {
            if var firstModifier = result.modifiers.first {
                firstModifier.leadingTrivia = savedLeadingTrivia
                result.modifiers[result.modifiers.startIndex] = firstModifier
            } else {
                result.bindingSpecifier.leadingTrivia = savedLeadingTrivia
            }
        }

        return DeclSyntax(result)
    }

    private func hasIBOutletAttribute(_ node: VariableDeclSyntax) -> Bool {
        node.attributes.contains { element in
            guard let attr = element.as(AttributeSyntax.self),
                let name = attr.attributeName.as(IdentifierTypeSyntax.self)
            else { return false }
            return name.name.text == "IBOutlet"
        }
    }
}

extension Finding.Message {
    fileprivate static let removeWeakFromOutlet: Finding.Message =
        "remove 'weak' from @IBOutlet property"
}
