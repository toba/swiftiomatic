struct InvalidCommandConfiguration: RuleConfiguration {
    let id = "invalid_command"
    let name = "Invalid Command"
    let summary = "sm: command is invalid"
    var nonTriggeringExamples: [Example] {
        [
              Example("// sm:disable unused_import"),
              Example("// sm:enable unused_import"),
              Example("// sm:disable:next unused_import"),
              Example("// sm:disable:previous unused_import"),
              Example("// sm:disable:this unused_import"),
              Example("//sm:disable:this unused_import"),
              Example(
                "_ = \"🤵🏼‍♀️\" // sm:disable:this unused_import",
                isExcludedFromDocumentation: true,
              ),
              Example(
                "_ = \"🤵🏼‍♀️ 🤵🏼‍♀️\" // sm:disable:this unused_import",
                isExcludedFromDocumentation: true,
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("// ↓sm:"),
              Example("// ↓sm: "),
              Example("// ↓sm::"),
              Example("// ↓sm:: "),
              Example("// ↓sm:disable"),
              Example("// ↓sm:dissable unused_import"),
              Example("// ↓sm:enaaaable unused_import"),
              Example("// ↓sm:disable:nxt unused_import"),
              Example("// ↓sm:enable:prevus unused_import"),
              Example("// ↓sm:enable:ths unused_import"),
              Example("// ↓sm:enable"),
              Example("// ↓sm:enable:"),
              Example("// ↓sm:enable: "),
              Example("// ↓sm:disable: unused_import"),
              Example("// s↓sm:disable unused_import"),
              Example("// 🤵🏼‍♀️sm:disable unused_import", isExcludedFromDocumentation: true),
            ]
    }
}
