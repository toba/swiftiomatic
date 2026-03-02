struct UnownedVariableCaptureConfiguration: RuleConfiguration {
    let id = "unowned_variable_capture"
    let name = "Unowned Variable Capture"
    let summary = "Prefer capturing references as weak to avoid potential crashes"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("foo { [weak self] in _ }"),
              Example("foo { [weak self] param in _ }"),
              Example("foo { [weak bar] in _ }"),
              Example("foo { [weak bar] param in _ }"),
              Example("foo { bar in _ }"),
              Example("foo { $0 }"),
              Example(
                """
                final class First {}
                final class Second {
                    unowned var value: First
                    init(value: First) {
                        self.value = value
                    }
                }
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("foo { [↓unowned self] in _ }"),
              Example("foo { [↓unowned bar] in _ }"),
              Example("foo { [bar, ↓unowned self] in _ }"),
            ]
    }
}
