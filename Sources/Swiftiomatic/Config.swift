import Foundation
import Yams

struct SwiftiomaticConfig {
    var enabledRules: [String]
    var disabledRules: [String]
    var indent: String
    var maxWidth: Int
    var swiftVersion: String

    static let `default` = SwiftiomaticConfig(
        enabledRules: [],
        disabledRules: [],
        indent: "    ",
        maxWidth: 120,
        swiftVersion: "6.2",
    )

    static func load(from path: String) throws -> SwiftiomaticConfig {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        guard let yaml = try Yams.load(yaml: String(data: data, encoding: .utf8) ?? "") as? [String: Any] else {
            return .default
        }
        guard let format = yaml["format"] as? [String: Any] else {
            return .default
        }

        var config = SwiftiomaticConfig.default

        if let rules = format["rules"] as? [String: Any] {
            if let enable = rules["enable"] as? [String] {
                config.enabledRules = enable
            }
            if let disable = rules["disable"] as? [String] {
                config.disabledRules = disable
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
