struct SpaceAroundBracketsConfiguration: RuleConfiguration {
    let id = "space_around_brackets"
    let name = "Space Around Brackets"
    let summary = "There should be no space between an identifier and opening bracket, and space after closing bracket before identifiers"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("foo[0]"),
              Example("foo as [String]"),
              Example("let a = [1, 2]"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("foo↓ [0]"),
              Example("foo↓as[String]"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("foo↓ [0]"): Example("foo[0]")
            ]
    }
}
