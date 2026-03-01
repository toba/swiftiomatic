struct NSLocalizedStringKeyConfiguration: RuleConfiguration {
    let id = "nslocalizedstring_key"
    let name = "NSLocalizedString Key"
    let summary = "Static strings should be used as key/comment in NSLocalizedString in order for genstrings to work"
    let isOptIn = true
}
