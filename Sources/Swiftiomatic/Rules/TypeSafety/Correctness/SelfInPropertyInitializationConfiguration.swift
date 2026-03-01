struct SelfInPropertyInitializationConfiguration: RuleConfiguration {
    let id = "self_in_property_initialization"
    let name = "Self in Property Initialization"
    let summary = "`self` refers to the unapplied `NSObject.self()` method, which is likely not expected; make the variable `lazy` to be able to refer to the current instance or use `ClassName.self`"
}
