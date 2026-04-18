/// Break around multiline dot-chained components.
package struct AroundMultilineExpressionChainComponents: LayoutDescriptor {
    package static let key = "aroundMultilineExpressionChainComponents"
    package static let group: ConfigGroup? = .lineBreaks
    package static let description = "Break around multiline dot-chained components."
    package static let defaultValue = false
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.lineBreakAroundMultilineExpressionChainComponents
}
