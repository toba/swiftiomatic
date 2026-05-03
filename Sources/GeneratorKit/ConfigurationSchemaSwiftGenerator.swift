import Foundation

/// Generates a Swift file that embeds the JSON Schema as a string literal, making it available at
/// runtime without SPM resource bundles.
package final class ConfigurationSchemaSwiftGenerator: FileGenerator {
    let schemaGenerator: ConfigurationSchemaGenerator

    package init(schemaGenerator: ConfigurationSchemaGenerator) {
        self.schemaGenerator = schemaGenerator
    }

    package func generateContent() -> String {
        let schemaJSON = schemaGenerator.generateContent()
        // Escape backslashes and interpolation in the raw string. Using a raw string literal
        // (triple-quoted with #) avoids most escaping.
        return """
            // Auto-generated — do not edit.

            // sm:ignore fileLength
            import Foundation

            /// The JSON Schema for the configuration, embedded as a decoded `JSONValue`
            /// for runtime validation.
            // sm:ignore typeBodyLength, closureBodyLength
            package enum ConfigurationSchema {
                package static let schema: JSONValue = {
                    let json = ##\"\"\"
            \(schemaJSON)
            \"\"\"##
                    let data = Data(json.utf8)
                    let decoder = JSONDecoder()
                    do {
                        return try decoder.decode(JSONValue.self, from: data)
                    } catch {
                        fatalError("Failed to decode embedded JSON Schema: \\(error) — regenerate with `swift run Generator`")
                    }
                }()
            }

            """
    }
}
