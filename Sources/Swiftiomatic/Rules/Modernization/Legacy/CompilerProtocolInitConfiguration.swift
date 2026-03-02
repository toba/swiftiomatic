struct CompilerProtocolInitConfiguration: RuleConfiguration {
    let id = "compiler_protocol_init"
    let name = "Compiler Protocol Init"
    let summary = "The initializers declared in compiler protocols such as `ExpressibleByArrayLiteral` shouldn't be called directly."
    var nonTriggeringExamples: [Example] {
        [
              Example("let set: Set<Int> = [1, 2]"),
              Example("let set = Set(array)"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("let set = ↓Set(arrayLiteral: 1, 2)"),
              Example("let set = ↓Set (arrayLiteral: 1, 2)"),
              Example("let set = ↓Set.init(arrayLiteral: 1, 2)"),
              Example("let set = ↓Set.init(arrayLiteral : 1, 2)"),
            ]
    }
}
