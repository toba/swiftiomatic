struct OptionalDataStringConversionConfiguration: RuleConfiguration {
    let id = "optional_data_string_conversion"
    let name = "Optional Data -> String Conversion"
    let summary = "Prefer failable `String(bytes:encoding:)` initializer when converting `Data` to `String`"
}
