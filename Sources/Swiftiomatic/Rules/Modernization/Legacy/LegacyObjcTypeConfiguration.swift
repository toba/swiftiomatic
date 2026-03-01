struct LegacyObjcTypeConfiguration: RuleConfiguration {
    let id = "legacy_objc_type"
    let name = "Legacy Objective-C Reference Type"
    let summary = "Prefer Swift value types to bridged Objective-C reference types"
    let isOptIn = true
}
