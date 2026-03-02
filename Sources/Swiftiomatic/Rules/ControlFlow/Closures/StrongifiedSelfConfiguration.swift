struct StrongifiedSelfConfiguration: RuleConfiguration {
    let id = "strongified_self"
    let name = "Strongified Self"
    let summary = "Remove backticks around `self` in optional unwrap expressions"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example("guard let self = self else { return }"),
              Example("guard let self else { return }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("guard let ↓`self` = self else { return }"),
            ]
    }
}
