struct NonOptionalStringDataConversionConfiguration: RuleConfiguration {
    private static let variablesIncluded = ["include_variables": true]
    let id = "non_optional_string_data_conversion"
    let name = "Non-optional String -> Data Conversion"
    let summary = "Prefer non-optional `Data(_:)` initializer when converting `String` to `Data`"
    var nonTriggeringExamples: [Example] {
        [
              Example("Data(\"foo\".utf8)"),
              Example("Data(string.utf8)"),
              Example("\"foo\".data(using: .ascii)"),
              Example("string.data(using: .unicode)"),
              Example("Data(\"foo\".utf8)", configuration: Self.variablesIncluded),
              Example("Data(string.utf8)", configuration: Self.variablesIncluded),
              Example("\"foo\".data(using: .ascii)", configuration: Self.variablesIncluded),
              Example("string.data(using: .unicode)", configuration: Self.variablesIncluded),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓\"foo\".data(using: .utf8)"),
              Example("↓\"foo\".data(using: .utf8)", configuration: Self.variablesIncluded),
              Example("↓string.data(using: .utf8)", configuration: Self.variablesIncluded),
              Example("↓property.data(using: .utf8)", configuration: Self.variablesIncluded),
              Example("↓obj.property.data(using: .utf8)", configuration: Self.variablesIncluded),
              Example("↓getString().data(using: .utf8)", configuration: Self.variablesIncluded),
              Example("↓getValue()?.data(using: .utf8)", configuration: Self.variablesIncluded),
            ]
    }
}
