struct ObservationPitfallsConfiguration: RuleConfiguration {
    let id = "observation_pitfalls"
    let name = "Observation Pitfalls"
    let summary = "Detects common pitfalls with the Observation framework"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("for await value in Observations({ [weak self] in self?.model }) { }")
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                for await value in ↓Observations({ self.model }) {
                    print(value)
                }
                """,
              )
            ]
    }
}
