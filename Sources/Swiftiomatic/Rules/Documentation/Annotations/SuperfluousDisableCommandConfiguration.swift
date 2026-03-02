struct SuperfluousDisableCommandConfiguration: RuleConfiguration {
    let id = "superfluous_disable_command"
    let name = "Superfluous Disable Command"
    let summary = ""
    var nonTriggeringExamples: [Example] {
        [
              Example("let abc:Void // sm:disable:this colon"),
              Example(
                """
                // sm:disable colon
                let abc:Void
                // sm:enable colon
                """,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let abc: Void // sm:disable:this colon"),
              Example(
                """
                // sm:disable colon
                let abc: Void
                // sm:enable colon
                """,
              ),
            ]
    }
}
