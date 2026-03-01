struct LinebreaksConfiguration: RuleConfiguration {
    let id = "linebreaks"
    let name = "Linebreaks"
    let summary = "Use consistent linebreak characters (LF)"
    let scope: Scope = .format
    let isCorrectable = true
}
