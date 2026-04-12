import SwiftiomaticSyntax

struct MissingDocsOptions: RuleOptions {
  typealias Parent = MissingDocsRule

  private(set) var parameters = [
    RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
    RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
  ]

  @OptionElement(key: "excludes_extensions")
  private(set) var excludesExtensions = true
  @OptionElement(key: "excludes_inherited_types")
  private(set) var excludesInheritedTypes = true
  @OptionElement(key: "excludes_trivial_init")
  private(set) var excludesTrivialInit = false
  @OptionElement(key: "evaluate_effective_access_control_level")
  private(set) var evaluateEffectiveAccessControlLevel = false

  var parameterDescription: RuleOptionsDescription? {
    let parametersDescription = Dictionary(grouping: parameters) { $0.severity }
      .sorted { $0.key.rawValue < $1.key.rawValue }
    if parametersDescription.isNotEmpty {
      for (severity, values) in parametersDescription {
        severity
          .rawValue => .list(values.map(\.value.description).sorted().map { .symbol($0) })
      }
    }
    $excludesExtensions.key => .flag(excludesExtensions)
    $excludesInheritedTypes.key => .flag(excludesInheritedTypes)
    $excludesTrivialInit.key => .flag(excludesTrivialInit)
    $evaluateEffectiveAccessControlLevel.key => .flag(evaluateEffectiveAccessControlLevel)
  }

  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    if let shouldExcludeExtensions = configuration[$excludesExtensions.key] as? Bool {
      excludesExtensions = shouldExcludeExtensions
    }

    if let shouldExcludeInheritedTypes = configuration[$excludesInheritedTypes.key] as? Bool {
      excludesInheritedTypes = shouldExcludeInheritedTypes
    }

    if let excludesTrivialInit = configuration[$excludesTrivialInit.key] as? Bool {
      self.excludesTrivialInit = excludesTrivialInit
    }

    if let evaluateEffectiveAccessControlLevel = configuration[
      $evaluateEffectiveAccessControlLevel.key,
    ]
      as? Bool
    {
      self.evaluateEffectiveAccessControlLevel = evaluateEffectiveAccessControlLevel
    }

    if let parameters = try parameters(from: configuration) {
      self.parameters = parameters
    }
  }

  private func parameters(from dict: [String: Any]) throws(SwiftiomaticError) -> [RuleParameter<
    AccessControlLevel,
  >]? {
    var parameters: [RuleParameter<AccessControlLevel>] = []

    for (key, value) in dict {
      guard let severity = Severity(rawValue: key) else {
        continue
      }

      if let array = [String].array(of: value) {
        let rules: [RuleParameter<AccessControlLevel>] =
          try array
          .map { val throws(SwiftiomaticError) -> RuleParameter<AccessControlLevel> in
            guard let acl = AccessControlLevel(description: val) else {
              throw .invalidConfiguration(ruleID: Parent.identifier)
            }
            return RuleParameter<AccessControlLevel>(severity: severity, value: acl)
          }

        parameters.append(contentsOf: rules)
      } else if let string = value as? String,
        let acl = AccessControlLevel(description: string)
      {
        let rule = RuleParameter<AccessControlLevel>(severity: severity, value: acl)

        parameters.append(rule)
      }
    }

    guard parameters.count == parameters.map(\.value).unique.count else {
      throw .invalidConfiguration(ruleID: Parent.identifier)
    }

    return parameters.isNotEmpty ? parameters : nil
  }
}
