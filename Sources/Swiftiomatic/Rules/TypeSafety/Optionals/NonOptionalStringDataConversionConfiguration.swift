struct NonOptionalStringDataConversionConfiguration: RuleConfiguration {
    let id = "non_optional_string_data_conversion"
    let name = "Non-optional String -> Data Conversion"
    let summary = "Prefer non-optional `Data(_:)` initializer when converting `String` to `Data`"
}
