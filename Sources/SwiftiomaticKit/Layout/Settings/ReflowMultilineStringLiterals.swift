/// Multiline string literal reflow mode.
package struct ReflowMultilineStringLiterals: LayoutDescriptor {
    package static let key = "reflowMultilineStringLiterals"
    package static let description = "Multiline string literal reflow mode."
    package static let defaultValue: MultilineStringReflowBehavior = .never
}

package enum MultilineStringReflowBehavior: String, Codable, Sendable {
    case never
    case onlyLinesOverLength
    case always

    var isNever: Bool { self == .never }
    var isAlways: Bool { self == .always }
}
