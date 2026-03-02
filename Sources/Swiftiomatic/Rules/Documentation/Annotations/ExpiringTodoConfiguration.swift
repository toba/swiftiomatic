struct ExpiringTodoConfiguration: RuleConfiguration {
    let id = "expiring_todo"
    let name = "Expiring Todo"
    let summary = "TODOs and FIXMEs should be resolved prior to their expiry date."
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("// notaTODO:"),
              Example("// notaFIXME:"),
              Example("// TODO: [12/31/9999]"),
              Example("// TODO(note)"),
              Example("// FIXME(note)"),
              Example("/* FIXME: */"),
              Example("/* TODO: */"),
              Example("/** FIXME: */"),
              Example("/** TODO: */"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("// TODO: [↓10/14/2019]"),
              Example("// FIXME: [↓10/14/2019]"),
              Example("// FIXME: [↓1/14/2019]"),
              Example("// FIXME: [↓10/14/2019]"),
              Example("// TODO: [↓9999/14/10]"),
            ]
    }
}
