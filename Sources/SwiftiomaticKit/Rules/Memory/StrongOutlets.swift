import SwiftSyntax

/// Remove `weak` from `@IBOutlet` properties.
///
/// As per Apple's recommendation, `@IBOutlet` properties should be strong. The `weak`
/// modifier is preserved for delegate and data source outlets since those are typically
/// owned elsewhere.
///
/// Lint: An `@IBOutlet` property with `weak` raises a warning.
///
/// Rewrite: The `weak` modifier is removed.
final class StrongOutlets: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .memory }

    /// Strip `weak` from `@IBOutlet` declarations (preserving it for `delegate`
    /// / `dataSource` outlets). Called from
    /// `CompactSyntaxRewriter.visit(_: VariableDeclSyntax)`.
    static func apply(_ node: VariableDeclSyntax, context: Context) -> VariableDeclSyntax {
        guard hasIBOutletAttribute(node), node.modifiers.contains(.weak) else {
            return node
        }

        if let name = node.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
            let lowercased = name.lowercased()
            if lowercased.hasSuffix("delegate") || lowercased.hasSuffix("datasource") {
                return node
            }
        }

        guard let weakModifier = node.modifiers.first(where: {
            $0.name.tokenKind == .keyword(.weak)
        }) else {
            return node
        }

        Self.diagnose(.removeWeakFromOutlet, on: weakModifier.name, context: context)

        var result = node
        let weakIsFirst = result.modifiers.first?.name.tokenKind == .keyword(.weak)
        let savedLeadingTrivia = weakIsFirst ? weakModifier.leadingTrivia : Trivia()

        result.modifiers.remove(anyOf: [.weak])

        if weakIsFirst {
            if var firstModifier = result.modifiers.first {
                firstModifier.leadingTrivia = savedLeadingTrivia
                result.modifiers[result.modifiers.startIndex] = firstModifier
            } else {
                result.bindingSpecifier.leadingTrivia = savedLeadingTrivia
            }
        }

        return result
    }

    private static func hasIBOutletAttribute(_ node: VariableDeclSyntax) -> Bool {
        node.attributes.contains { element in
            if let attr = element.as(AttributeSyntax.self),
               let name = attr.attributeName.as(IdentifierTypeSyntax.self)
            {
                name.name.text == "IBOutlet"
            } else {
                false
            }
        }
    }
}

extension Finding.Message {
    fileprivate static let removeWeakFromOutlet: Finding.Message =
        "remove 'weak' from @IBOutlet property"
}
