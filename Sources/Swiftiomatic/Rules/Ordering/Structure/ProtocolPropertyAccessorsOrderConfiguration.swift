struct ProtocolPropertyAccessorsOrderConfiguration: RuleConfiguration {
    let id = "protocol_property_accessors_order"
    let name = "Protocol Property Accessors Order"
    let summary = "When declaring properties in protocols, the order of accessors should be `get set`"
    let isCorrectable = true
}
