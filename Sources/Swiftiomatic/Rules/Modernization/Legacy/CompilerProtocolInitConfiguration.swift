struct CompilerProtocolInitConfiguration: RuleConfiguration {
    let id = "compiler_protocol_init"
    let name = "Compiler Protocol Init"
    let summary = "The initializers declared in compiler protocols such as `ExpressibleByArrayLiteral` shouldn't be called directly."
}
