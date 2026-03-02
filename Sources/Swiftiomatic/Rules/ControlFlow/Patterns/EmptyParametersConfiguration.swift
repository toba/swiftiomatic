struct EmptyParametersConfiguration: RuleConfiguration {
    let id = "empty_parameters"
    let name = "Empty Parameters"
    let summary = "Prefer `() -> ` over `Void -> `"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let abc: () -> Void = {}"),
              Example("func foo(completion: () -> Void)"),
              Example("func foo(completion: () throws -> Void)"),
              Example("let foo: (ConfigurationTests) -> Void throws -> Void)"),
              Example("let foo: (ConfigurationTests) ->   Void throws -> Void)"),
              Example("let foo: (ConfigurationTests) ->Void throws -> Void)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let abc: ↓(Void) -> Void = {}"),
              Example("func foo(completion: ↓(Void) -> Void)"),
              Example("func foo(completion: ↓(Void) throws -> Void)"),
              Example("let foo: ↓(Void) -> () throws -> Void)"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let abc: ↓(Void) -> Void = {}"): Example("let abc: () -> Void = {}"),
              Example("func foo(completion: ↓(Void) -> Void)"): Example(
                "func foo(completion: () -> Void)",
              ),
              Example("func foo(completion: ↓(Void) throws -> Void)"):
                Example("func foo(completion: () throws -> Void)"),
              Example("let foo: ↓(Void) -> () throws -> Void)"): Example(
                "let foo: () -> () throws -> Void)",
              ),
            ]
    }
}
