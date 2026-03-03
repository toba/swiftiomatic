import Yams
import Foundation

// MARK: - YamlParser

/// Parses YAML configuration strings into untyped dictionaries
enum YamlParser {
    /// Parses a YAML string into an untyped dictionary
    ///
    /// YAML is inherently untyped -- the Yams library returns `Any` for all values.
    /// Callers are responsible for casting values to concrete types immediately
    /// after parsing (see ``Configuration/loadUnified(from:)``).
    ///
    /// - Parameters:
    ///   - yaml: YAML-formatted string.
    ///   - env: The environment used to expand `${VAR}` references in the YAML.
    /// - Returns: The parsed YAML as an untyped dictionary.
    /// - Throws: ``SwiftiomaticError/yamlParsing(_:)`` if the string cannot be parsed.
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

extension Constructor {
    fileprivate static func customConstructor(env: [String: String]) -> Constructor {
        Constructor(customScalarMap(env: env))
    }

    fileprivate static func customScalarMap(env: [String: String]) -> ScalarMap {
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

extension String {
    fileprivate func expandingEnvVars(env: [String: String]) -> String {
        guard contains("${") else {
            // No environment variables used.
            return self
        }
        return env.reduce(into: self) { result, envVar in
            result = result.replacingOccurrences(of: "${\(envVar.key)}", with: envVar.value)
        }
    }
}
