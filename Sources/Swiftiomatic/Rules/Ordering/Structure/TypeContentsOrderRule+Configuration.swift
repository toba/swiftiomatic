enum TypeContent: String, AcceptableByConfigurationElement {
  case `case`
  case typeAlias = "type_alias"
  case associatedType = "associated_type"
  case subtype
  case typeProperty = "type_property"
  case instanceProperty = "instance_property"
  case ibOutlet = "ib_outlet"
  case ibInspectable = "ib_inspectable"
  case initializer
  case typeMethod = "type_method"
  case viewLifeCycleMethod = "view_life_cycle_method"
  case ibAction = "ib_action"
  case otherMethod = "other_method"
  case `subscript`
  case deinitializer
  case ibSegueAction = "ib_segue_action"
}

struct TypeContentsOrderConfiguration: SeverityBasedRuleConfiguration {
  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "order")
  private(set) var order: [[TypeContent]] = [
    [.case],
    [.typeAlias, .associatedType],
    [.subtype],
    [.typeProperty],
    [.instanceProperty],
    [.ibInspectable],
    [.ibOutlet],
    [.initializer],
    [.typeMethod],
    [.viewLifeCycleMethod],
    [.ibAction, .ibSegueAction],
    [.otherMethod],
    [.subscript],
    [.deinitializer],
  ]
  typealias Parent = TypeContentsOrderRule
  mutating func apply(configuration: [String: Any]) throws(Issue) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$order.key] {
      try order.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    try validate()
  }
}
