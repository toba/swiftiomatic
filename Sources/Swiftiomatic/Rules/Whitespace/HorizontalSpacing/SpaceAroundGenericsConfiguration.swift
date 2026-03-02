struct SpaceAroundGenericsConfiguration: RuleConfiguration {
    let id = "space_around_generics"
    let name = "Space Around Generics"
    let summary = "There should be no space between an identifier and opening angle bracket"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let a: Array<Int> = []"),
              Example("func foo<T>() {}"),
              Example("class Foo<T> {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let a: Array↓ <Int> = []"),
              Example("func foo↓ <T>() {}"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let a: Array↓ <Int> = []"): Example("let a: Array<Int> = []")
            ]
    }
}
