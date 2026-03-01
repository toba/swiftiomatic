struct JoinedDefaultParameterConfiguration: RuleConfiguration {
    let id = "joined_default_parameter"
    let name = "Joined Default Parameter"
    let summary = "Discouraged explicit usage of the default separator"
    let isCorrectable = true
    let isOptIn = true
}
