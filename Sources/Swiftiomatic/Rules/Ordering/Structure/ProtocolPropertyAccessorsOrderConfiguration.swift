struct ProtocolPropertyAccessorsOrderConfiguration: RuleConfiguration {
    let id = "protocol_property_accessors_order"
    let name = "Protocol Property Accessors Order"
    let summary = "When declaring properties in protocols, the order of accessors should be `get set`"
    let isCorrectable = true
    var nonTriggeringExamples: [Example] {
        [
              Example("protocol Foo {\n var bar: String { get set }\n }"),
              Example("protocol Foo {\n var bar: String { get }\n }"),
              Example("protocol Foo {\n var bar: String { set }\n }"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Example("protocol Foo {\n var bar: String { ↓set get }\n }")
            ]
    }
    var corrections: [Example: Example] {
        [
              Example("protocol Foo {\n var bar: String { ↓set get }\n }"):
                Example("protocol Foo {\n var bar: String { get set }\n }")
            ]
    }
}
