import SwiftSyntax

/// Capitalize acronyms when the first character is capitalized.
///
/// When an identifier contains a titlecased acronym (e.g. `Url` , `Json` , `Id` ), it should be
/// fully uppercased (e.g. `URL` , `JSON` , `ID` ) for consistency with Swift naming conventions.
///
/// The list of recognized acronyms is configurable via `Configuration.acronyms` .
///
/// Lint: An identifier with a titlecased acronym raises a warning.
///
/// Rewrite: The titlecased acronym is replaced with the uppercased form. The compact pipeline calls
/// `applyUppercaseAcronyms` directly from `Rewrites/Tokens/TokenRewrites.swift` . This class only
/// exists so the rule is registered (configuration key, group, default value). It has no visit /
/// transform / willEnter / didExit methods — `RuleCollector` allows that.
final class UppercaseAcronymsInIdentifiers: StaticFormatRule<AcronymsConfiguration>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .naming }
    override static var defaultValue: AcronymsConfiguration {
        var config = AcronymsConfiguration()
        config.rewrite = false
        config.lint = .no
        return config
    }
}

// MARK: - Configuration

package struct AcronymsConfiguration: SyntaxRuleValue {
    package var rewrite = true
    package var lint: Lint = .warn
    /// Acronyms that should be fully uppercased when they appear at the start of an identifier
    /// already written in PascalCase. Replace this list to override the defaults; entries should be
    /// uppercase, e.g. `"URL"` , `"ID"` .
    package var words: [String] = [
        "ID", "URL", "UUID", "HTTP", "HTTPS", "JSON", "XML", "HTML",
        "API", "TCP", "UDP", "DNS", "SSH", "FTP", "SQL", "CSS",
        "RGB", "RGBA", "PDF", "GIF", "PNG", "JPEG",
    ]

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }
        words = try container.decodeIfPresent([String].self, forKey: .words)
            ?? AcronymsConfiguration().words
    }
}
