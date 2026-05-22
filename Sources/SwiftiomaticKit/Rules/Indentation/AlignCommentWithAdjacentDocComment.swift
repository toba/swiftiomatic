/// Indent a regular `//` comment one extra space when it directly follows a `///` doc
/// comment, so its body aligns with the doc comment body.
package struct AlignCommentWithAdjacentDocComment: LayoutRule {
    package static let group: ConfigurationGroup? = .indentation
    package static let description =
        "Indent a regular '//' comment one extra space when it directly follows a '///' doc "
        + "comment, so its body aligns with the doc comment body."
    package static let defaultValue = true
}
