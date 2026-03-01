struct DiscouragedObjectLiteralConfiguration: RuleConfiguration {
    let id = "discouraged_object_literal"
    let name = "Discouraged Object Literal"
    let summary = "Prefer initializers over object literals"
    let isOptIn = true
}
