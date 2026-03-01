struct FatalErrorMessageConfiguration: RuleConfiguration {
    let id = "fatal_error_message"
    let name = "Fatal Error Message"
    let summary = "A fatalError call should have a message"
    let isOptIn = true
}
