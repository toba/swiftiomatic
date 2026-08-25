import SwiftSyntax

/// Collapse a full five-platform `@available` list into the `anyAppleOS` domain.
///
/// Swift 6.4 adds `anyAppleOS` , which stands for macOS, iOS, tvOS, watchOS and visionOS at once.
/// Five separate clauses have to be kept in sync by hand, and one that drifts silently changes what
/// the declaration is available on.
///
/// The rewrite fires only when all five platforms appear at the same version, and when the
/// attribute carries nothing else. A shorter list is left alone, because it names the platforms the
/// author chose and `anyAppleOS` would widen it. A list with `deprecated:` , `message:` ,
/// `renamed:` or `unavailable` is left alone for the same reason.
///
/// Lint: A five-platform `@available` list at one version raises a warning.
///
/// Rewrite: The five clauses collapse to a single `anyAppleOS` clause, keeping the trailing `*` .
final class UseAnyAppleOSAvailability: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    /// The platforms `anyAppleOS` stands for. All five must be present for the rewrite to be
    /// equivalent.
    private static let appleOSPlatforms: Set<String> = [
        "macOS", "iOS", "tvOS", "watchOS", "visionOS",
    ]

    static func transform(
        _ node: AttributeSyntax,
        original _: AttributeSyntax,
        parent _: Syntax?,
        context: Context
    ) -> AttributeSyntax {
        guard let name = node.attributeName.as(IdentifierTypeSyntax.self),
            name.name.text == "available",
            case let .availability(arguments)? = node.arguments,
            let collapsed = collapse(arguments) else { return node }

        Self.diagnose(.useAnyAppleOS, on: node.atSign, context: context)
        return node.with(\.arguments, .availability(collapsed))
    }

    /// The rewritten argument list, or `nil` when the attribute does not qualify.
    private static func collapse(
        _ arguments: AvailabilityArgumentListSyntax
    ) -> AvailabilityArgumentListSyntax? {
        var restrictions = [(index: Int, platform: PlatformVersionSyntax)]()
        var wildcardIndex: Int?

        for (index, argument) in arguments.enumerated() {
            switch argument.argument {
                case let .availabilityVersionRestriction(platform):
                    restrictions.append((index, platform))
                case let .token(token) where token.tokenKind == .binaryOperator("*"):
                    guard wildcardIndex == nil else { return nil }
                    wildcardIndex = index
                default:
                    // A label such as `deprecated:` or `message:` means the attribute says more
                    // than "available from", so collapsing it would drop information.
                    return nil
            }
        }

        // The wildcard must close the list. Binding it here states the invariant once, so the
        // rebuild below cannot fall back to a wrong element if this guard ever changes.
        guard let wildcardIndex, wildcardIndex == arguments.count - 1 else { return nil }

        let names = Set(restrictions.map(\.platform.platform.text))
        guard names == appleOSPlatforms, restrictions.count == appleOSPlatforms.count
        else { return nil }

        guard let first = restrictions.first,
              let version = first.platform.version?.trimmedDescription,
              restrictions.allSatisfy({ $0.platform.version?.trimmedDescription == version })
        else { return nil }

        return rebuild(arguments, keeping: first, wildcardIndex: wildcardIndex)
    }

    /// Rewrites the list to one `anyAppleOS` clause plus the wildcard, reusing the first
    /// restriction's trivia so the attribute keeps its original spacing.
    private static func rebuild(
        _ arguments: AvailabilityArgumentListSyntax,
        keeping first: (index: Int, platform: PlatformVersionSyntax),
        wildcardIndex: Int
    ) -> AvailabilityArgumentListSyntax {
        let elements = Array(arguments)
        let renamed = first.platform.with(
            \.platform,
            first.platform.platform.with(\.tokenKind, .identifier("anyAppleOS"))
        )
        let collapsed = elements[first.index].with(
            \.argument, .availabilityVersionRestriction(renamed))
        return AvailabilityArgumentListSyntax([collapsed, elements[wildcardIndex]])
    }
}

fileprivate extension Finding.Message {
    static let useAnyAppleOS: Finding.Message =
        "five platform clauses have to be kept in sync by hand — collapse them to '@available(anyAppleOS …, *)'"
}
