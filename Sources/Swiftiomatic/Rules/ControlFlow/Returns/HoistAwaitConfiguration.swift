struct HoistAwaitConfiguration: RuleConfiguration {
    let id = "hoist_await"
    let name = "Hoist Await"
    let summary = "Move `await` keyword to the outermost expression instead of nesting it inside arguments"
    let scope: Scope = .format
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let result = await foo(bar)"),
              Example("let result = await foo(bar, baz)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let result = foo(↓await bar())"),
              Example("let result = foo(↓await bar(), baz)"),
              Example("let result = [↓await foo(), ↓await bar()]"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let result = foo(↓await bar())"): Example("let result = await foo(bar())")
            ]
    }
}
