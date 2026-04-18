/// Multiline string literal reflow mode.
package struct ReflowMultilineStringLiterals: LayoutDescriptor {
    package static let key = "reflowMultilineStringLiterals"
    package static let description = "Multiline string literal reflow mode."
    package static let defaultValue: Configuration.MultilineStringReflowBehavior = .never
    package static let schema: ConfigProperty.Schema = .stringEnum(
        description: description,
        values: ["never", "onlyLinesOverLength", "always"],
        defaultValue: "never"
    )
    package static let keyPath = \Configuration.reflowMultilineStringLiterals
}
