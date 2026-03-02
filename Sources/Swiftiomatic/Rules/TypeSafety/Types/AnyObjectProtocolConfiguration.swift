struct AnyObjectProtocolConfiguration: RuleConfiguration {
    let id = "any_object_protocol"
    let name = "AnyObject Protocol"
    let summary = "Prefer `AnyObject` over `class` in protocol definitions"
    let scope: Scope = .suggest
    var nonTriggeringExamples: [Example] {
        [
              Example("protocol Foo: AnyObject {}"),
              Example("protocol Foo: Sendable {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("protocol Foo: ↓class {}"),
            ]
    }
}
