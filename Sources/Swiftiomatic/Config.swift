import Yams
import Foundation

struct SwiftiomaticConfig {
    // MARK: - Lint Rule Configuration

    /// Lint rules explicitly enabled (for opt-in rules).
    var enabledLintRules: [String]

    /// Lint rules explicitly disabled.
    var disabledRules: [String]

    /// Per-rule configuration overrides (keyed by rule identifier).
    var lintRuleConfigs: [String: Any]

    // MARK: - Format Configuration

    /// Format rules explicitly enabled.
    var enabledFormatRules: [String]

    /// Format rules explicitly disabled.
    var disabledFormatRules: [String]

    var indent: String
    var maxWidth: Int
    var swiftVersion: String

    // MARK: - Suggest Configuration

    var suggestMinConfidence: String

    nonisolated(unsafe) static let `default` = SwiftiomaticConfig(
        enabledLintRules: [],
        disabledRules: [],
        lintRuleConfigs: [:],
        enabledFormatRules: [],
        disabledFormatRules: [],
        indent: "    ",
        maxWidth: 120,
        swiftVersion: "6.2",
        suggestMinConfidence: "low",
    )

    static func load(from path: String) throws -> SwiftiomaticConfig {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        guard
            let yaml = try Yams
            .load(yaml: String(data: data, encoding: .utf8) ?? "") as? [String: Any]
        else {
            return .default
        }

        var config = SwiftiomaticConfig.default

        // Rules section (lint rule configuration)
        if let rules = yaml["rules"] as? [String: Any] {
            if let enabled = rules["enabled"] as? [String] {
                config.enabledLintRules = enabled
            }
            if let disabled = rules["disabled"] as? [String] {
                config.disabledRules = disabled
            }
            if let ruleConfig = rules["config"] as? [String: Any] {
                config.lintRuleConfigs = ruleConfig
            }
        }

        // Suggest section
        if let suggest = yaml["suggest"] as? [String: Any] {
            if let confidence = suggest["min_confidence"] as? String {
                config.suggestMinConfidence = confidence
            }
        }

        // Format section
        if let format = yaml["format"] as? [String: Any] {
            if let rules = format["rules"] as? [String: Any] {
                if let enable = rules["enable"] as? [String] {
                    config.enabledFormatRules = enable
                }
                if let disable = rules["disable"] as? [String] {
                    config.disabledFormatRules = disable
                }
            }

            if let options = format["options"] as? [String: Any] {
                if let indent = options["indent"] as? String {
                    config.indent = indent
                }
                if let maxWidth = options["maxwidth"] as? Int {
                    config.maxWidth = maxWidth
                }
                if let version = options["swiftversion"] as? String {
                    config.swiftVersion = version
                }
            }
        }

        // Legacy: top-level "exclude" adds to disabled rules list
        if let exclude = yaml["exclude"] as? [String] {
            config.disabledRules += exclude
        }

        return config
    }

    /// Find config file by walking up from the given directory
    static func find(from directory: String) -> String? {
        let fm = FileManager.default
        var components = (directory as NSString).pathComponents
        while !components.isEmpty {
            let dir = NSString.path(withComponents: components)
            let candidate = (dir as NSString).appendingPathComponent(".swiftiomatic.yaml")
            if fm.fileExists(atPath: candidate) {
                return candidate
            }
            components.removeLast()
        }
        return nil
    }
}
