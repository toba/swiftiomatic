import SwiftSyntax

/// Capitalize acronyms when the first character is capitalized.
///
/// When an identifier contains a titlecased acronym (e.g. `Url`, `Json`, `Id`),
/// it should be fully uppercased (e.g. `URL`, `JSON`, `ID`) for consistency with
/// Swift naming conventions.
///
/// The list of recognized acronyms is configurable via `Configuration.acronyms`.
///
/// Lint: An identifier with a titlecased acronym raises a warning.
///
/// Format: The titlecased acronym is replaced with the uppercased form.
final class CapitalizeAcronyms: SyntaxFormatRule {
    static let group: ConfigGroup? = .capitalization
    static let isOptIn = true

    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        guard case .identifier(let text) = token.tokenKind else {
            return token
        }

        let acronyms = context.configuration.acronyms.words
        let updated = capitalizeAcronyms(in: text, acronyms: acronyms)

        guard updated != text else { return token }

        diagnose(.capitalizeAcronym, on: token)
        return token.with(\.tokenKind, .identifier(updated))
    }

    /// Scans the text for titlecased acronyms and replaces them with uppercased versions.
    private func capitalizeAcronyms(in text: String, acronyms: [String]) -> String {
        var result = text
        // Sort longest first so longer acronyms match before shorter substrings
        let sortedAcronyms = acronyms.sorted { $0.count > $1.count }

        for acronym in sortedAcronyms {
            guard acronym.count >= 2 else { continue }
            let titlecased = acronym.capitalized  // e.g. "URL" → "Url"
            result = replaceAcronym(titlecased, with: acronym.uppercased(), in: result)
        }
        return result
    }

    /// Replace occurrences of a titlecased acronym with its uppercased form,
    /// but only when followed by an uppercase letter, end of string, or 's' + uppercase/end.
    private func replaceAcronym(_ titlecased: String, with uppercased: String, in text: String)
        -> String
    {
        var result = ""
        var index = text.startIndex

        while index < text.endIndex {
            let remaining = text[index...]
            if remaining.hasPrefix(titlecased) {
                let afterMatch = text.index(index, offsetBy: titlecased.count)
                if isAcronymBoundary(text, at: afterMatch) {
                    result += uppercased
                    index = afterMatch
                    continue
                }
            }
            // Also skip already-uppercased acronyms so we don't double-process
            if remaining.hasPrefix(uppercased) {
                let afterMatch = text.index(index, offsetBy: uppercased.count)
                result += uppercased
                index = afterMatch
                continue
            }
            result.append(text[index])
            index = text.index(after: index)
        }
        return result
    }

    /// Returns true if `index` is at a valid acronym boundary (end of string, uppercase letter,
    /// or 's' followed by uppercase/end).
    private func isAcronymBoundary(_ text: String, at index: String.Index) -> Bool {
        guard index < text.endIndex else { return true }
        let char = text[index]
        if char.isUppercase { return true }
        // Handle plural: "Ids" → "IDs"
        if char == "s" {
            let next = text.index(after: index)
            return next >= text.endIndex || text[next].isUppercase
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let capitalizeAcronym: Finding.Message =
        "capitalize acronyms in identifier"
}

// MARK: - Configuration

package struct AcronymsConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
    package static let configProperties: [ConfigProperty] = [
        .init(
            "words",
            .stringArray(
                description: "Acronyms to capitalize (fully uppercased).",
                defaultValue: [
                    "API", "CSS", "DNS", "FTP", "GIF", "HTML", "HTTP", "HTTPS",
                    "ID", "JPEG", "JSON", "PDF", "PNG", "RGB", "RGBA",
                    "SQL", "SSH", "TCP", "UDP", "URL", "UUID", "XML",
                ]
            )
        )
    ]

    package var words: [String] = [
        "ID", "URL", "UUID", "HTTP", "HTTPS", "JSON", "XML", "HTML",
        "API", "TCP", "UDP", "DNS", "SSH", "FTP", "SQL", "CSS",
        "RGB", "RGBA", "PDF", "GIF", "PNG", "JPEG",
    ]

    package init() {}

    package init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self()
        self.words =
            try container.decodeIfPresent([String].self, forKey: .words)
            ?? defaults.words
    }
}
