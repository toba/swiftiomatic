struct SpaceInsideBracketsConfiguration: RuleConfiguration {
    let id = "space_inside_brackets"
    let name = "Space Inside Brackets"
    let summary = "There should be no spaces immediately inside square brackets"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let a = [1, 2, 3]"),
              Example("let b = foo[0]"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let a = [↓ 1, 2, 3 ]"),
              Example("let b = foo[↓ 0 ]"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let a = [↓ 1, 2, 3 ]"): Example("let a = [1, 2, 3]")
            ]
    }
}
