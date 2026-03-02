struct ForceTryConfiguration: RuleConfiguration {
    let id = "force_try"
    let name = "Force Try"
    let summary = "Force tries should be avoided"
    var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                func a() throws {}
                do {
                  try a()
                } catch {}
                """,
              )
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example(
                """
                func a() throws {}
                ↓try! a()
                """,
              )
            ]
    }
}
