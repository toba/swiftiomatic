import Yams
import Foundation

// MARK: - YamlParser

/// An interface for parsing YAML.
enum YamlParser {
    /// Parses the input YAML string as an untyped dictionary.
    ///
    /// YAML is inherently untyped — the Yams library returns `Any` for all values.
    /// Callers are responsible for casting values to concrete types immediately
    /// after parsing (see ``Configuration/loadUnified(from:)``).
    ///
    /// - parameter yaml: YAML-formatted string.
    /// - parameter env:  The environment to use to expand variables in the YAML.
    ///
    /// - returns: The parsed YAML as an untyped dictionary.
    ///
    /// - throws: Throws if the `yaml` string provided could not be parsed.
    static func parse(
        _ yaml: String,
        env: [String: String] = ProcessInfo.processInfo.environment,
    ) throws(SwiftiomaticError) -> [String: Any] {
        do {
            return try Yams.load(
                yaml: yaml, .default,
                .customConstructor(env: env),
            ) as? [String: Any] ?? [:]
        } catch {
            throw SwiftiomaticError.yamlParsing("\(error)")
        }
    }
}

private extension Constructor {
    static func customConstructor(env: [String: String]) -> Constructor {
        Constructor(customScalarMap(env: env))
    }

    static func customScalarMap(env: [String: String]) -> ScalarMap {
        var map = defaultScalarMap
        map[.str] = { $0.string.expandingEnvVars(env: env) }
        map[.bool] = {
            switch $0.string.expandingEnvVars(env: env).lowercased() {
                case "true": true
                case "false": false
                default: nil
            }
        }
        map[.int] = { Int($0.string.expandingEnvVars(env: env)) }
        map[.float] = { Double($0.string.expandingEnvVars(env: env)) }
        return map
    }
}

private extension String {
    func expandingEnvVars(env: [String: String]) -> String {
        guard contains("${") else {
            // No environment variables used.
            return self
        }
        return env.reduce(into: self) { result, envVar in
            result = result.replacingOccurrences(of: "${\(envVar.key)}", with: envVar.value)
        }
    }
}
