struct TodoConfiguration: RuleConfiguration {
    let id = "todo"
    let name = "Todo"
    let summary = "TODOs and FIXMEs should be resolved."
    var nonTriggeringExamples: [Example] {
        [
              Example("// notaTODO:"),
              Example("// notaFIXME:"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("// ↓TODO:"),
              Example("// ↓FIXME:"),
              Example("// ↓TODO(note)"),
              Example("// ↓FIXME(note)"),
              Example("/* ↓FIXME: */"),
              Example("/* ↓TODO: */"),
              Example("/** ↓FIXME: */"),
              Example("/** ↓TODO: */"),
            ]
    }
}
