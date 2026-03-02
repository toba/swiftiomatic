struct SelfBindingConfiguration: RuleConfiguration {
    let id = "self_binding"
    let name = "Self Binding"
    let summary = "Re-bind `self` to a consistent identifier name."
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("if let self = self { return }"),
              Example("guard let self = self else { return }"),
              Example("if let this = this { return }"),
              Example("guard let this = this else { return }"),
              Example("if let this = self { return }", configuration: ["bind_identifier": "this"]),
              Example(
                "guard let this = self else { return }",
                configuration: ["bind_identifier": "this"],
              ),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("if let ↓`self` = self { return }"),
              Example("guard let ↓`self` = self else { return }"),
              Example("if let ↓this = self { return }"),
              Example("guard let ↓this = self else { return }"),
              Example("if let ↓self = self { return }", configuration: ["bind_identifier": "this"]),
              Example(
                "guard let ↓self = self else { return }",
                configuration: ["bind_identifier": "this"],
              ),
              Example("if let ↓self { return }", configuration: ["bind_identifier": "this"]),
              Example("guard let ↓self else { return }", configuration: ["bind_identifier": "this"]),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("if let ↓`self` = self { return }"):
                Example("if let self = self { return }"),
              Example("guard let ↓`self` = self else { return }"):
                Example("guard let self = self else { return }"),
              Example("if let ↓this = self { return }"):
                Example("if let self = self { return }"),
              Example("guard let ↓this = self else { return }"):
                Example("guard let self = self else { return }"),
              Example("if let ↓self = self { return }", configuration: ["bind_identifier": "this"]):
                Example(
                  "if let this = self { return }",
                  configuration: ["bind_identifier": "this"],
                ),
              Example("if let ↓self { return }", configuration: ["bind_identifier": "this"]):
                Example(
                  "if let this = self { return }",
                  configuration: ["bind_identifier": "this"],
                ),
              Example("guard let ↓self else { return }", configuration: ["bind_identifier": "this"]):
                Example(
                  "guard let this = self else { return }",
                  configuration: ["bind_identifier": "this"],
                ),
            ]
    }
}
