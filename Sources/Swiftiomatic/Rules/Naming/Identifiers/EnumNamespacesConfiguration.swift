struct EnumNamespacesConfiguration: RuleConfiguration {
    let id = "enum_namespaces"
    let name = "Enum Namespaces"
    let summary = "Types hosting only static members should be enums to prevent instantiation"
    let scope: Scope = .suggest
}
