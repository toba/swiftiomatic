struct LinebreaksConfiguration: RuleConfiguration {
    let id = "linebreaks"
    let name = "Linebreaks"
    let summary = "Use consistent linebreak characters (LF)"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let a = 0\nlet b = 1\n")
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let a = 0\r\n↓let b = 1\r\n")
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let a = 0\r\n↓let b = 1\r\n"): Example("let a = 0\nlet b = 1\n")
            ]
    }
}
