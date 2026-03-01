struct RedundantMemberwiseInitConfiguration: RuleConfiguration {
    let id = "redundant_memberwise_init"
    let name = "Redundant Memberwise Init"
    let summary = "Structs get an automatic memberwise initializer; explicit ones that mirror it are redundant"
    let scope: Scope = .suggest
}
