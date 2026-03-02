struct ToggleBoolConfiguration: RuleConfiguration {
    let id = "toggle_bool"
    let name = "Toggle Bool"
    let summary = "Prefer `someBool.toggle()` over `someBool = !someBool`"
    let isCorrectable = true
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              Example("isHidden.toggle()"),
              Example("view.clipsToBounds.toggle()"),
              Example("func foo() { abc.toggle() }"),
              Example("view.clipsToBounds = !clipsToBounds"),
              Example("disconnected = !connected"),
              Example("result = !result.toggle()"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("↓isHidden = !isHidden"),
              Example("↓view.clipsToBounds = !view.clipsToBounds"),
              Example("func foo() { ↓abc = !abc }"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("↓isHidden = !isHidden"): Example("isHidden.toggle()"),
              Example("↓view.clipsToBounds = !view.clipsToBounds"): Example(
                "view.clipsToBounds.toggle()",
              ),
              Example("func foo() { ↓abc = !abc }"): Example("func foo() { abc.toggle() }"),
            ]
    }
}
