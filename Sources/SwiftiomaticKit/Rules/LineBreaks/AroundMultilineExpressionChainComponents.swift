/// Break around multiline dot-chained components.
package struct AroundMultilineExpressionChainComponents: LayoutRule {
    package static let key = "aroundMultilineExpressionChainComponents"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description = "Break around multiline dot-chained components."
    package static let defaultValue = false
}
