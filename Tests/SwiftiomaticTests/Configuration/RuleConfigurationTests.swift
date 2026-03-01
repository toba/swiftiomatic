import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct RuleConfigurationTests {
  private let defaultNestingConfiguration = NestingConfiguration(
    typeLevel: SeverityLevelsConfiguration(warning: 0),
    functionLevel: SeverityLevelsConfiguration(warning: 0),
  )

  @Test func nestingConfigurationSetsCorrectly() {
    let config =
      [
        "type_level": [
          "warning": 7, "error": 17,
        ],
        "function_level": [
          "warning": 8, "error": 18,
        ],
        "check_nesting_in_closures_and_statements": false,
        "always_allow_one_type_in_functions": true,
      ] as [String: any Sendable]
    var nestingConfig = defaultNestingConfiguration
    do {
      try nestingConfig.apply(configuration: config)
      #expect(nestingConfig.typeLevel.warning == 7)
      #expect(nestingConfig.functionLevel.warning == 8)
      #expect(nestingConfig.typeLevel.error == 17)
      #expect(nestingConfig.functionLevel.error == 18)
      #expect(nestingConfig.alwaysAllowOneTypeInFunctions)
      #expect(!nestingConfig.checkNestingInClosuresAndStatements)
    } catch {
      Issue.record("Failed to configure nested configurations")
    }
  }

  @Test func nestingConfigurationThrowsOnBadConfig() {
    let config: [String: Any] = ["type_level": "not_a_number"]
    var nestingConfig = defaultNestingConfiguration
    checkError(Issue.invalidConfiguration(ruleID: NestingRule.identifier)) {
      try nestingConfig.apply(configuration: config)
    }
  }

  @Test func severityWorksAsOnlyParameter() throws {
    var config = AttributesConfiguration()
    #expect(config.severity == .warning)
    try config.apply(configuration: ["severity": "error"])
    #expect(config.severity == .error)
  }

  @Test func severityConfigurationFromString() {
    let config: [String: Any] = ["severity": "Warning"]
    let comp = SeverityConfiguration<MockRule>(.warning)
    var severityConfig = SeverityConfiguration<MockRule>(.error)
    do {
      try severityConfig.apply(configuration: config)
      #expect(severityConfig == comp)
    } catch {
      Issue.record("Failed to configure severity from string")
    }
  }

  @Test func severityConfigurationFromDictionary() {
    let config = ["severity": "warning"]
    let comp = SeverityConfiguration<MockRule>(.warning)
    var severityConfig = SeverityConfiguration<MockRule>(.error)
    do {
      try severityConfig.apply(configuration: config)
      #expect(severityConfig == comp)
    } catch {
      Issue.record("Failed to configure severity from dictionary")
    }
  }

  @Test func severityConfigurationThrowsNothingApplied() {
    let config: [String: Any] = ["unrelated_key": 17]
    var severityConfig = SeverityConfiguration<MockRule>(.error)
    checkError(Issue.nothingApplied(ruleID: MockRule.identifier)) {
      try severityConfig.apply(configuration: config)
    }
  }

  @Test func severityConfigurationThrowsInvalidConfiguration() {
    let config: [String: Any] = ["severity": "foo"]
    var severityConfig = SeverityConfiguration<MockRule>(.warning)
    checkError(Issue.invalidConfiguration(ruleID: MockRule.identifier)) {
      try severityConfig.apply(configuration: config)
    }
  }

  @Test func severityLevelConfigParams() {
    let severityConfig = SeverityLevelsConfiguration<MockRule>(warning: 17, error: 7)
    #expect(
      severityConfig.params == [
        RuleParameter(severity: .error, value: 7),
        RuleParameter(
          severity: .warning,
          value: 17,
        ),
      ],
    )
  }

  @Test func severityLevelConfigPartialParams() {
    let severityConfig = SeverityLevelsConfiguration<MockRule>(warning: 17, error: nil)
    #expect(severityConfig.params == [RuleParameter(severity: .warning, value: 17)])
  }

  @Test func severityLevelConfigApplyNilErrorValue() throws {
    var severityConfig = SeverityLevelsConfiguration<MockRule>(warning: 17, error: 20)
    // Specifying warning without error causes error to be set to nil
    try severityConfig.apply(configuration: ["warning": 18])
    #expect(severityConfig.params == [RuleParameter(severity: .warning, value: 18)])
  }

  @Test func severityLevelConfigApplyMissingErrorValue() throws {
    var severityConfig = SeverityLevelsConfiguration<MockRule>(warning: 17, error: 20)
    try severityConfig.apply(configuration: ["warning": 18])
    #expect(severityConfig.params == [RuleParameter(severity: .warning, value: 18)])
  }

  @Test func trailingWhitespaceConfigurationThrowsOnBadConfig() {
    let config: [String: Any] = ["severity": "unknown"]
    var configuration = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: false,
      ignoresComments: true,
      ignoresLiterals: false,
    )
    checkError(Issue.invalidConfiguration(ruleID: TrailingWhitespaceRule.identifier)) {
      try configuration.apply(configuration: config)
    }
  }

  @Test func trailingWhitespaceConfigurationInitializerSetsIgnoresEmptyLines() {
    let configuration1 = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: false,
      ignoresComments: true,
      ignoresLiterals: false,
    )
    #expect(!(configuration1.ignoresEmptyLines))

    let configuration2 = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: true,
      ignoresComments: true,
      ignoresLiterals: false,
    )
    #expect(configuration2.ignoresEmptyLines)
  }

  @Test func trailingWhitespaceConfigurationInitializerSetsIgnoresComments() {
    let configuration1 = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: false,
      ignoresComments: true,
      ignoresLiterals: false,
    )
    #expect(configuration1.ignoresComments)

    let configuration2 = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: false,
      ignoresComments: false,
      ignoresLiterals: false,
    )
    #expect(!(configuration2.ignoresComments))
  }

  @Test func trailingWhitespaceConfigurationApplyConfigurationSetsIgnoresEmptyLines() {
    var configuration = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: false,
      ignoresComments: true,
      ignoresLiterals: false,
    )
    do {
      let config1 = ["ignores_empty_lines": true]
      try configuration.apply(configuration: config1)
      #expect(configuration.ignoresEmptyLines)

      let config2 = ["ignores_empty_lines": false]
      try configuration.apply(configuration: config2)
      #expect(!(configuration.ignoresEmptyLines))
    } catch {
      Issue.record("Failed to apply ignores_empty_lines")
    }
  }

  @Test func trailingWhitespaceConfigurationApplyConfigurationSetsIgnoresComments() {
    var configuration = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: false,
      ignoresComments: true,
      ignoresLiterals: false,
    )
    do {
      let config1 = ["ignores_comments": true]
      try configuration.apply(configuration: config1)
      #expect(configuration.ignoresComments)

      let config2 = ["ignores_comments": false]
      try configuration.apply(configuration: config2)
      #expect(!(configuration.ignoresComments))
    } catch {
      Issue.record("Failed to apply ignores_comments")
    }
  }

  @Test func trailingWhitespaceConfigurationCompares() {
    let configuration1 = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: false,
      ignoresComments: true,
      ignoresLiterals: false,
    )
    let configuration2 = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: true,
      ignoresComments: true,
      ignoresLiterals: false,
    )
    #expect(configuration1 != configuration2)

    let configuration3 = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: true,
      ignoresComments: true,
      ignoresLiterals: false,
    )
    #expect(configuration2 == configuration3)

    let configuration4 = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: false,
      ignoresComments: false,
      ignoresLiterals: false,
    )

    #expect(configuration1 != configuration4)

    let configuration5 = TrailingWhitespaceConfiguration(
      ignoresEmptyLines: true,
      ignoresComments: false,
      ignoresLiterals: false,
    )

    #expect(configuration1 != configuration5)
  }

  @Test func trailingWhitespaceConfigurationApplyConfigurationUpdatesSeverityConfiguration() {
    var configuration = TrailingWhitespaceConfiguration(
      severityConfiguration: .warning,
      ignoresEmptyLines: false,
      ignoresComments: true,
    )

    do {
      try configuration.apply(configuration: ["severity": "error"])
      #expect(configuration.severityConfiguration.severity == .error)
    } catch {
      Issue.record("Failed to apply severity")
    }
  }

  @Test func overriddenSuperCallConfigurationFromDictionary() {
    var configuration = OverriddenSuperCallConfiguration()
    #expect(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))

    let conf1 = ["severity": "error", "excluded": "viewWillAppear(_:)"]
    do {
      try configuration.apply(configuration: conf1)
      #expect(configuration.severityConfiguration.severity == .error)
      #expect(!(configuration.resolvedMethodNames.contains("*")))
      #expect(!(configuration.resolvedMethodNames.contains("viewWillAppear(_:)")))
      #expect(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))
    } catch {
      Issue.record("Failed to apply configuration for \(conf1)")
    }

    let conf2 =
      [
        "severity": "error",
        "excluded": "viewWillAppear(_:)",
        "included": ["*", "testMethod1()", "testMethod2(_:)"],
      ] as [String: any Sendable]
    do {
      try configuration.apply(configuration: conf2)
      #expect(configuration.severityConfiguration.severity == .error)
      #expect(!(configuration.resolvedMethodNames.contains("*")))
      #expect(!(configuration.resolvedMethodNames.contains("viewWillAppear(_:)")))
      #expect(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))
      #expect(configuration.resolvedMethodNames.contains("testMethod1()"))
      #expect(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
    } catch {
      Issue.record("Failed to apply configuration for \(conf2)")
    }

    let conf3 =
      [
        "severity": "warning",
        "excluded": "*",
        "included": ["testMethod1()", "testMethod2(_:)"],
      ] as [String: any Sendable]
    do {
      try configuration.apply(configuration: conf3)
      #expect(configuration.severityConfiguration.severity == .warning)
      #expect(configuration.resolvedMethodNames.count == 2)
      #expect(!(configuration.resolvedMethodNames.contains("*")))
      #expect(configuration.resolvedMethodNames.contains("testMethod1()"))
      #expect(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
    } catch {
      Issue.record("Failed to apply configuration for \(conf3)")
    }
  }

  @Test func modifierOrderConfigurationFromDictionary() throws {
    var configuration = ModifierOrderConfiguration()
    let config: [String: Any] = [
      "severity": "warning",
      "preferred_modifier_order": [
        "override",
        "acl",
        "setterACL",
        "owned",
        "mutators",
        "final",
        "typeMethods",
        "required",
        "convenience",
        "lazy",
        "dynamic",
      ],
    ]

    try configuration.apply(configuration: config)
    let expected: [SwiftDeclarationAttributeKind.ModifierGroup] = [
      .override,
      .acl,
      .setterACL,
      .owned,
      .mutators,
      .final,
      .typeMethods,
      .required,
      .convenience,
      .lazy,
      .dynamic,
    ]
    #expect(configuration.severityConfiguration.severity == .warning)
    #expect(configuration.preferredModifierOrder == expected)
  }

  @Test func modifierOrderConfigurationThrowsOnUnrecognizedModifierGroup() {
    var configuration = ModifierOrderConfiguration()
    let config =
      [
        "severity": "warning",
        "preferred_modifier_order": ["specialize"],
      ] as [String: any Sendable]

    checkError(Issue.invalidConfiguration(ruleID: ModifierOrderRule.identifier)) {
      try configuration.apply(configuration: config)
    }
  }

  @Test func modifierOrderConfigurationThrowsOnNonModifiableGroup() {
    var configuration = ModifierOrderConfiguration()
    let config =
      [
        "severity": "warning",
        "preferred_modifier_order": ["atPrefixed"],
      ] as [String: any Sendable]
    checkError(Issue.invalidConfiguration(ruleID: ModifierOrderRule.identifier)) {
      try configuration.apply(configuration: config)
    }
  }

  @Test func computedAccessorsOrderRuleConfiguration() throws {
    var configuration = ComputedAccessorsOrderConfiguration()
    let config = ["severity": "error", "order": "set_get"]
    try configuration.apply(configuration: config)

    #expect(configuration.severityConfiguration.severity == .error)
    #expect(configuration.order == .setGet)

    #expect(
      RuleConfigurationDescription.from(configuration: configuration).oneLiner()
        == "severity: error; order: set_get",
    )
  }
}
