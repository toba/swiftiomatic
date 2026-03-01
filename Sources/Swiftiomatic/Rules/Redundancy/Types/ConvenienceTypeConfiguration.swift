struct ConvenienceTypeConfiguration: RuleConfiguration {
    let id = "convenience_type"
    let name = "Convenience Type"
    let summary = "Types used for hosting only static members should be implemented as a caseless enum to avoid instantiation"
    let isOptIn = true
}
