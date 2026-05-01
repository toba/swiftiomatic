/// Break before else/catch after closing brace.
package struct ElseCatchOnNewLine: LayoutRule {
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description = "Break before else/catch after closing brace."
    package static let defaultValue = false
}
