/// Trailing comma handling in multiline lists.
package struct MultilineTrailingCommaBehaviorSetting: LayoutRule {
    package static let key = "multilineTrailingCommaBehavior"
    package static let description = "Trailing comma handling in multiline lists."
    package static let defaultValue: MultilineTrailingCommaBehavior = .keptAsWritten
}

package enum MultilineTrailingCommaBehavior: String, Codable, Sendable {
    case alwaysUsed
    case neverUsed
    case keptAsWritten
}
