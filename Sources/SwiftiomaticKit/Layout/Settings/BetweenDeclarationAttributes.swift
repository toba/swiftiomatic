/// Break between adjacent attributes.
package struct BetweenDeclarationAttributes: LayoutDescriptor {
    package static let key = "betweenDeclarationAttributes"
    package static let group: ConfigGroup? = .lineBreaks
    package static let description = "Break between adjacent attributes."
    package static let defaultValue = false
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.lineBreakBetweenDeclarationAttributes
}
