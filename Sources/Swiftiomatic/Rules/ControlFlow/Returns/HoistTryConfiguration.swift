struct HoistTryConfiguration: RuleConfiguration {
    let id = "hoist_try"
    let name = "Hoist Try"
    let summary = "Move `try` keyword to the outermost expression instead of nesting it inside arguments"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let result = try foo(bar)"),
              Example("let result = try foo(bar, baz)"),
              Example("try foo()"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let result = foo(↓try bar())"),
              Example("let result = foo(↓try bar(), baz)"),
              Example("let result = [↓try foo(), ↓try bar()]"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let result = foo(↓try bar())"): Example("let result = try foo(bar())")
            ]
    }
}
