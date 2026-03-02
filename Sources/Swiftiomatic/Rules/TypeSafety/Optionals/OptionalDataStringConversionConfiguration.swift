struct OptionalDataStringConversionConfiguration: RuleConfiguration {
    let id = "optional_data_string_conversion"
    let name = "Optional Data -> String Conversion"
    let summary = "Prefer failable `String(bytes:encoding:)` initializer when converting `Data` to `String`"
    var nonTriggeringExamples: [Example] {
        [
              Example("String(data: data, encoding: .utf8)"),
              Example("String(bytes: data, encoding: .utf8)"),
              Example("String(UTF8.self)"),
              Example("String(a, b, c, UTF8.self)"),
              Example("String(decoding: data, encoding: UTF8.self)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("String(decoding: data, as: UTF8.self)")
            ]
    }
}
