struct ProhibitedInterfaceBuilderConfiguration: RuleConfiguration {
    let id = "prohibited_interface_builder"
    let name = "Prohibited Interface Builder"
    let summary = "Creating views using Interface Builder should be avoided"
    let isOptIn = true
}
