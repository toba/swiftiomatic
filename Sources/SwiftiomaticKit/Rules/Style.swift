/// Selected formatting style. Drives the format pipeline's stage-1 normalizations
/// and the pretty printer's break-precedence preferences.
///
/// `compact` is the only fully-implemented style. `roomy` is a reserved name —
/// selecting it currently fails (see `0ev-1u9`).
package struct StyleSetting: LayoutRule {
    package static let key = "style"
    package static let group: ConfigurationGroup? = nil
    package static let description = "Formatting style. Drives normalization and layout choices."
    package static let defaultValue: Style = .compact
}

package enum Style: String, Codable, Sendable, CaseIterable {
    /// Default. Prefers single-line constructs; wraps only when exceeding line length.
    case compact
    /// Reserved — not yet implemented. Selecting this style fails until a future epic.
    case roomy
}
