/// Treat a solitary closing brace as a blank line for blank-line rules.
package struct TreatClosingBraceAsBlankLine: LayoutRule {
    package static let group: ConfigurationGroup? = .blankLines
    package static let description = "Treat a solitary closing brace as a blank line."
    package static let defaultValue = false
}
