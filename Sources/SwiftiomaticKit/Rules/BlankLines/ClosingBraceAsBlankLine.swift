/// Treat a solitary closing brace as a blank line for blank-line rules.
package struct ClosingBraceAsBlankLine: LayoutRule {
    package static let key = "closingBraceAsBlankLine"
    package static let group: ConfigurationGroup? = .blankLines
    package static let description = "Treat a solitary closing brace as a blank line."
    package static let defaultValue = false
}
