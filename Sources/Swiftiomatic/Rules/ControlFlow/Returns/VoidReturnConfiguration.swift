struct VoidReturnConfiguration: RuleConfiguration {
    let id = "void_return"
    let name = "Void Return"
    let summary = "Prefer `-> Void` over `-> ()`"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("let abc: () -> Void = {}"),
              Example("let abc: () -> (VoidVoid) = {}"),
              Example("func foo(completion: () -> Void)"),
              Example("let foo: (ConfigurationTests) -> () throws -> Void"),
              Example("let foo: (ConfigurationTests) ->   () throws -> Void"),
              Example("let foo: (ConfigurationTests) ->() throws -> Void"),
              Example("let foo: (ConfigurationTests) -> () -> Void"),
              Example("let foo: () -> () async -> Void"),
              Example("let foo: () -> () async throws -> Void"),
              Example("let foo: () -> () async -> Void"),
              Example("func foo() -> () async throws -> Void {}"),
              Example("func foo() async throws -> () async -> Void { return {} }"),
              Example("func foo() -> () async -> Int { 1 }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let abc: () -> ↓() = {}"),
              Example("let abc: () -> ↓(Void) = {}"),
              Example("let abc: () -> ↓(   Void ) = {}"),
              Example("func foo(completion: () -> ↓())"),
              Example("func foo(completion: () -> ↓(   ))"),
              Example("func foo(completion: () -> ↓(Void))"),
              Example("let foo: (ConfigurationTests) -> () throws -> ↓()"),
              Example("func foo() async -> ↓()"),
              Example("func foo() async throws -> ↓()"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("let abc: () -> ↓() = {}"): Example("let abc: () -> Void = {}"),
              Example("let abc: () -> ↓(Void) = {}"): Example("let abc: () -> Void = {}"),
              Example("let abc: () -> ↓(   Void ) = {}"): Example("let abc: () -> Void = {}"),
              Example("func foo(completion: () -> ↓())"): Example("func foo(completion: () -> Void)"),
              Example("func foo(completion: () -> ↓(   ))"): Example(
                "func foo(completion: () -> Void)",
              ),
              Example("func foo(completion: () -> ↓(Void))"): Example(
                "func foo(completion: () -> Void)",
              ),
              Example("let foo: (ConfigurationTests) -> () throws -> ↓()"):
                Example("let foo: (ConfigurationTests) -> () throws -> Void"),
              Example("func foo() async throws -> ↓()"): Example("func foo() async throws -> Void"),
            ]
    }
}
