/// Treat a comment line as a blank line for blank-line rules.
package struct TreatCommentAsBlankLine: LayoutRule {
    package static let group: ConfigurationGroup? = .blankLines
    package static let description = "Treat a comment line as a blank line."
    package static let defaultValue = false
}
