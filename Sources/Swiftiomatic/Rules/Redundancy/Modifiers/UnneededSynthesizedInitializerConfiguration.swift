struct UnneededSynthesizedInitializerConfiguration: RuleConfiguration {
    let id = "unneeded_synthesized_initializer"
    let name = "Unneeded Synthesized Initializer"
    let summary = "Default or memberwise initializers that will be automatically synthesized do not need to be manually defined."
    let isCorrectable = true
}
