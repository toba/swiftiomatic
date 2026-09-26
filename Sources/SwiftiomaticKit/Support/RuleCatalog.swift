import Foundation
import ConfigurationKit

/// The metadata of one rule that reporters and `sm explain` show to a reader.
package struct RuleInfo: Sendable {
    /// The configuration key, which is also the rule ID in lint output.
    package let key: String

    /// The key with its group prefix, such as `redundancies.dropBacktickedSelf`.
    package let qualifiedKey: String

    /// How strong the advice of the rule is.
    package let guidance: GuidanceLevel

    /// The full doc comment of the rule.
    package let documentation: String

    /// The first sentence of the doc comment. It says when the rule applies.
    package let applicability: String
}

/// Looks up rule metadata by rule ID.
///
/// The documentation comes from the embedded configuration schema. The generator copies each rule's
/// doc comment into the schema, so the catalog needs no generated code of its own.
package enum RuleCatalog {
    /// Every rule, sorted by key.
    package static let all: [RuleInfo] = ConfigurationRegistry.allRuleTypes
        .map { ruleType in
            let documentation = documentation(key: ruleType.key, group: ruleType.group)
                ?? ruleType.key
            return RuleInfo(
                key: ruleType.key,
                qualifiedKey: ruleType.qualifiedKey,
                guidance: ruleType.guidance,
                documentation: documentation,
                applicability: firstSentence(of: documentation)
            )
        }
        .sorted { $0.key < $1.key }

    private static let byKey = Dictionary(all.map { ($0.key, $0) }, uniquingKeysWith: { a, _ in a })

    /// Returns the rule that the name identifies, or `nil` when no rule has that name.
    ///
    /// - Parameter name: A rule key, a qualified key or a rule type name. Case does not matter.
    package static func info(for name: String) -> RuleInfo? {
        if let info = byKey[name] { return info }

        let key = String(name.split(separator: ".").last ?? "")
        if let info = byKey[key] ?? byKey[configurationKey(forTypeName: key)] { return info }

        let lowercased = key.lowercased()
        return all.first { $0.key.lowercased() == lowercased }
    }

    /// Returns the full text that `sm explain <rule>` prints.
    package static func explanation(of info: RuleInfo) -> String {
        """
        \(info.key) (\(info.qualifiedKey))
        Guidance: \(info.guidance.rawValue)
        Applies when: \(info.applicability)

        \(info.documentation)
        """
    }

    /// Returns one line per rule with its key, guidance level and applicability.
    package static func listing() -> String {
        let width = all.map(\.key.count).max() ?? 0
        let guidanceWidth = GuidanceLevel.allCases.map(\.rawValue.count).max() ?? 0

        return all.map { info in
            let key = info.key.padding(toLength: width, withPad: " ", startingAt: 0)
            let guidance = info.guidance.rawValue
                .padding(toLength: guidanceWidth, withPad: " ", startingAt: 0)
            return "\(key)  \(guidance)  \(info.applicability)"
        }
        .joined(separator: "\n")
    }

    /// Returns the first sentence of the text, on one line.
    ///
    /// A sentence ends at a period outside inline code that comes before the end of the text or
    /// before whitespace and an uppercase letter. This keeps `e.g.` and code such as `a.b` intact.
    static func firstSentence(of text: String) -> String {
        let paragraph = text.split(separator: "\n\n", maxSplits: 1).first.map(String.init) ?? text
        let flattened = paragraph.split(whereSeparator: \.isNewline).joined(separator: " ")
        let characters = Array(flattened)
        var inCode = false

        for index in characters.indices {
            switch characters[index] {
                case "`": inCode.toggle()
                case "." where !inCode:
                    let rest = characters[(index + 1)...].drop { $0 == " " }
                    let endsSentence = rest.isEmpty
                        || (rest.startIndex > index + 1 && rest.first?.isUppercase == true)
                    if endsSentence { return String(characters[...index]) }
                default: break
            }
        }
        return flattened.trimmingCharacters(in: .whitespaces)
    }

    /// Reads the rule's description from the embedded schema.
    private static func documentation(key: String, group: ConfigurationGroup?) -> String? {
        var node = ConfigurationSchema.schema
        if let group { node = node.member("properties")?.member(group.rawValue) ?? .null }
        guard case let .string(text)? = node.member("properties")?.member(key)?.member("description")
        else { return nil }
        return text
    }
}

private extension JSONValue {
    func member(_ name: String) -> JSONValue? {
        guard case let .object(members) = self else { return nil }
        return members[name]
    }
}
