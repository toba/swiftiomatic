/// Spaces before end-of-line comments.
package struct SpacesBeforeEndOfLineComments: LayoutRule {
    package static let group: ConfigurationGroup? = .spaces
    package static let description = "Spaces before // comments."
    package static let defaultValue = 2
}
