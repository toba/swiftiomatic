import SwiftSyntax

/// Flag a second property wrapper on a `@State` property.
///
/// SwiftUI finds the storage of `@State` through the property wrapper that the view declares. A
/// second wrapper composes around `State` or inside it, so SwiftUI does not install the storage as
/// it expects. The property then loses its value or does not update the view.
///
/// Apply the other behavior to the value itself, or keep the value in an `@Observable` model. The
/// rule does not flag `@Previewable` , and it does not flag built-in declaration attributes such as
/// `@MainActor` or `@available` .
///
/// Lint: A variable declaration has the attribute `@State` and another custom attribute.
final class NoStackedStateWrapper: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    /// Attributes that are not property wrappers
    private static let nonWrapperAttributes: Set<String> = [
        "MainActor", "available", "objc", "nonobjc", "preconcurrency", "Previewable",
        "usableFromInline", "inlinable", "_spi", "backDeployed", "exclusivity",
        "warn_unqualified_access", "IBOutlet", "IBInspectable", "GKInspectable", "NSCopying",
        "NSManaged", "ObservationIgnored", "ObservationTracked", "Transient", "retroactive",
    ]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let attributes = node.attributes.compactMap { element -> (AttributeSyntax, String)? in
            guard case let .attribute(attribute) = element,
                  let name = Self.simpleName(of: attribute) else { return nil }
            return (attribute, name)
        }
        guard attributes.contains(where: { $0.1 == "State" }) else { return .visitChildren }

        for (attribute, name) in attributes
        where name != "State" && !Self.nonWrapperAttributes.contains(name) {
            diagnose(.stackedWrapper(name), on: attribute)
        }
        return .visitChildren
    }

    /// The last name component of the attribute, such as `State` for `@SwiftUI.State`
    private static func simpleName(of attribute: AttributeSyntax) -> String? {
        if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
            return identifier.name.text
        }
        return attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
    }
}

fileprivate extension Finding.Message {
    static func stackedWrapper(_ name: String) -> Finding.Message {
        "'@\(name)' stacks a second property wrapper on '@State'. SwiftUI does not support a second wrapper on '@State'"
    }
}
