import SwiftSyntax

/// Zero-width and other invisible Unicode characters in string literals are almost always typos or
/// paste artifacts. They're impossible to see in source and cause string equality, lookup, and URL
/// parsing to silently fail.
///
/// The default character set is U+200B (zero-width space), U+200C (zero-width non-joiner), and
/// U+FEFF (BOM). Configure additional code points via `invisibleCharacters.additionalCodePoints`
/// (an array of hex strings, e.g. `["00AD", "200D"]` ).
///
/// Lint: When a string literal segment contains any of the configured invisible code points, an
/// error is raised at the offending character.
final class InvisibleCharacters: LintSyntaxRule<InvisibleCharactersConfiguration>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .literals }
    override class var defaultValue: InvisibleCharactersConfiguration {
        var config = InvisibleCharactersConfiguration()
        config.lint = .error
        return config
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        let invalidScalars = ruleConfig.resolvedScalars
        for segment in node.segments {
            guard let stringSegment = segment.as(StringSegmentSyntax.self) else { continue }
            for scalar in stringSegment.content.text.unicodeScalars
            where invalidScalars.contains(scalar) {
                diagnose(.invisibleCharacter(name: name(for: scalar)), on: node)
            }
        }
        return .visitChildren
    }

    private func name(for scalar: Unicode.Scalar) -> String {
        let hex = String(scalar.value, radix: 16, uppercase: true)
        let padded = String(repeating: "0", count: max(0, 4 - hex.count)) + hex
        if let description = InvisibleCharactersConfiguration.builtinDescriptions[scalar] {
            return "U+\(padded) (\(description))"
        }
        return "U+\(padded)"
    }
}

fileprivate extension Finding.Message {
    static func invisibleCharacter(name: String) -> Finding.Message {
        "string literal contains invisible character \(name)"
    }
}

// MARK: - Configuration

package struct InvisibleCharactersConfiguration: SyntaxRuleValue {
    package var rewrite = false
    package var lint: Lint = .error
    /// Extra invisible code points to flag, beyond the built-in set (U+200B zero-width space,
    /// U+200C zero-width non-joiner, U+FEFF BOM). Each entry is a hex string with no prefix, e.g.
    /// `"00AD"` , `"200D"` .
    package var additionalCodePoints: [String] = []

    /// Built-in default invisible code points and their human-readable names.
    package static let builtinDescriptions: [Unicode.Scalar: String] = [
        "\u{200B}": "zero-width space",
        "\u{200C}": "zero-width non-joiner",
        "\u{FEFF}": "zero-width no-break space",
    ]

    /// Combined set of built-in and configured code points.
    package var resolvedScalars: Set<Unicode.Scalar> {
        var set = Set(Self.builtinDescriptions.keys)
        for hex in additionalCodePoints {
            if let value = UInt32(hex, radix: 16),
               let scalar = Unicode.Scalar(value)
            {
                set.insert(scalar)
            }
        }
        return set
    }

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let rewrite = try container.decodeIfPresent(Bool.self, forKey: .rewrite) {
            self.rewrite = rewrite
        }
        if let lint = try container.decodeIfPresent(Lint.self, forKey: .lint) { self.lint = lint }

        additionalCodePoints = try container.decodeIfPresent(
            [String].self, forKey: .additionalCodePoints) ?? []
    }
}
