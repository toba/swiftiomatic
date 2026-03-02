struct FireAndForgetTaskConfiguration: RuleConfiguration {
    let id = "fire_and_forget_task"
    let name = "Fire and Forget Task"
    let summary = "Enhanced fire-and-forget Task detection with scope-aware severity and .onAppear+Task analysis"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let task = Task { await work() }"),
              Example("return Task { await work() }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                deinit {
                    ↓Task { await cleanup() }
                }
                """,
              )
            ]
    }
}
