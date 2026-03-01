extension Configuration {
    // MARK: - Subtypes

    enum Key: String, CaseIterable {
        case cachePath = "cache_path"
        case disabledRules = "disabled_rules"
        case enabledRules = "enabled_rules" // deprecated in favor of optInRules
        case excluded
        case included
        case optInRules = "opt_in_rules"
        case onlyRules = "only_rules"
        case indentation
        case analyzerRules = "analyzer_rules"
    }

    // MARK: - Properties

    private static let validGlobalKeys: Set<String> = Set(Key.allCases.map(\.rawValue))

    // MARK: - Initializers

    /// Create a ``Configuration`` value from a parsed YAML dictionary
    ///
    /// - Parameters:
    ///   - dict: The untyped dictionary to serve as the input, typically generated from a YAML file.
    ///   - ruleList: The list of rules to be available to this configuration.
    ///   - enableAllRules: Whether all rules from `ruleList` should be enabled regardless of `dict`.
    ///   - onlyRule: Rules to restrict the run to.
    ///   - cachePath: The location of the persisted cache on disk.
    init(
        dict: [String: Any],
        ruleList: RuleList = RuleRegistry.shared.list,
        enableAllRules: Bool = false,
        onlyRule: [String] = [],
        cachePath: String? = nil,
    ) throws {
        func defaultStringArray(_ object: Any?) -> [String] {
            [String].array(of: object) ?? []
        }

        // Use either the new 'opt_in_rules' or fallback to the deprecated 'enabled_rules'
        let optInRules = defaultStringArray(
            dict[Key.optInRules.rawValue] ?? dict[Key.enabledRules.rawValue],
        )
        let disabledRules = defaultStringArray(dict[Key.disabledRules.rawValue])

        let onlyRules = defaultStringArray(dict[Key.onlyRules.rawValue])
        let analyzerRules = defaultStringArray(dict[Key.analyzerRules.rawValue])

        Self.warnAboutInvalidKeys(configurationDictionary: dict, ruleList: ruleList)
        Self.warnAboutDeprecations(
            configurationDictionary: dict, disabledRules: disabledRules,
            optInRules: optInRules, onlyRules: onlyRules, ruleList: ruleList,
        )
        Self.warnAboutMisplacedAnalyzerRules(optInRules: optInRules, ruleList: ruleList)

        let allRulesWrapped: [ConfiguredRule]
        do {
            allRulesWrapped = try ruleList.allRulesWrapped(configurationDict: dict)
        } catch let RuleListError.duplicatedConfigurations(ruleType) {
            let aliases = ruleType.description.deprecatedAliases.map { "'\($0)'" }
                .joined(separator: ", ")
            let identifier = ruleType.identifier
            throw SwiftiomaticError.genericWarning(
                "Multiple configurations found for '\(identifier)'. Check for any aliases: \(aliases).",
            )
        }

        let rulesMode = try RulesMode(
            enableAllRules: enableAllRules,
            onlyRule: onlyRule,
            onlyRules: onlyRules,
            optInRules: optInRules,
            disabledRules: disabledRules,
            analyzerRules: analyzerRules,
        )

        if onlyRule.isEmpty {
            Self.validateConfiguredRulesAreEnabled(
                configurationDictionary: dict,
                ruleList: ruleList,
                rulesMode: rulesMode,
            )
        }

        self.init(
            rulesMode: rulesMode,
            allRulesWrapped: allRulesWrapped,
            ruleList: ruleList,
            includedPaths: defaultStringArray(dict[Key.included.rawValue]),
            excludedPaths: defaultStringArray(dict[Key.excluded.rawValue]),
            indentation: Self.getIndentationLogIfInvalid(from: dict),
            cachePath: cachePath ?? dict[Key.cachePath.rawValue] as? String,
        )
    }

    // MARK: - Methods: Validations

    private static func validKeys(ruleList: RuleList) -> Set<String> {
        validGlobalKeys.union(ruleList.allValidIdentifiers())
    }

    private static func getIndentationLogIfInvalid(from dict: [String: Any]) -> IndentationStyle {
        if let rawIndentation = dict[Key.indentation.rawValue] {
            if let indentationStyle = IndentationStyle(rawIndentation) {
                return indentationStyle
            }
            SwiftiomaticError.invalidConfiguration(ruleID: Key.indentation.rawValue).print()
            return .default
        }

        return .default
    }

    private static func warnAboutDeprecations(
        configurationDictionary dict: [String: Any],
        disabledRules: [String] = [],
        optInRules: [String] = [],
        onlyRules: [String] = [],
        ruleList: RuleList,
    ) {
        // Deprecation warning for "enabled_rules"
        if dict[Key.enabledRules.rawValue] != nil {
            SwiftiomaticError.renamedIdentifier(old: Key.enabledRules.rawValue, new: Key.optInRules.rawValue)
                .print()
        }

        // Deprecation warning for rules
        let deprecatedRulesIdentifiers = ruleList.rules.flatMap {
            identifier, rule -> [(String, String)] in
            rule.description.deprecatedAliases.map { ($0, identifier) }
        }

        let userProvidedRuleIDs = Set(disabledRules + optInRules + onlyRules)
        let deprecatedUsages = deprecatedRulesIdentifiers.filter { deprecatedIdentifier, _ in
            dict[deprecatedIdentifier] != nil || userProvidedRuleIDs.contains(deprecatedIdentifier)
        }

        for (deprecatedIdentifier, identifier) in deprecatedUsages {
            SwiftiomaticError.renamedIdentifier(old: deprecatedIdentifier, new: identifier).print()
        }
    }

    private static func warnAboutInvalidKeys(
        configurationDictionary dict: [String: Any], ruleList: RuleList,
    ) {
        // Log an error when supplying invalid keys in the configuration dictionary
        let invalidKeys = Set(dict.keys).subtracting(validKeys(ruleList: ruleList))
        if invalidKeys.isNotEmpty {
            SwiftiomaticError.invalidRuleIDs(invalidKeys).print()
        }
    }

    private static func validateConfiguredRulesAreEnabled(
        configurationDictionary dict: [String: Any],
        ruleList: RuleList,
        rulesMode: RulesMode,
    ) {
        for key in dict.keys where !validGlobalKeys.contains(key) {
            guard let identifier = ruleList.identifier(for: key),
                  let ruleType = ruleList.rules[identifier]
            else {
                continue
            }

            switch rulesMode {
                case .allCommandLine, .onlyCommandLine:
                    return
                case let .onlyConfiguration(onlyRules):
                    if onlyRules.isDisjoint(with: ruleType.description.allIdentifiers) {
                        SwiftiomaticError.ruleNotPresentInOnlyRules(ruleID: ruleType.identifier).print()
                    }
                case let .defaultConfiguration(disabled: disabledRules, optIn: optInRules):
                    let issue = validateConfiguredRuleIsEnabled(
                        disabledRules: disabledRules,
                        optInRules: optInRules,
                        ruleType: ruleType,
                    )
                    issue?.print()
            }
        }
    }

    static func validateConfiguredRuleIsEnabled(
        disabledRules: Set<String>,
        optInRules: Set<String>,
        ruleType: any Rule.Type,
    ) -> SwiftiomaticError? {
        let allEnabledRules = optInRules.subtracting(disabledRules)
        let allIdentifiers = ruleType.description.allIdentifiers

        if allEnabledRules.isDisjoint(with: allIdentifiers) {
            if !disabledRules.isDisjoint(with: allIdentifiers) {
                return SwiftiomaticError.ruleDisabledInDisabledRules(ruleID: ruleType.identifier)
            }

            if ruleType is any OptInRule.Type {
                if optInRules.isDisjoint(with: allIdentifiers) {
                    return SwiftiomaticError.ruleNotEnabledInOptInRules(ruleID: ruleType.identifier)
                }
            }
        }

        return nil
    }

    private static func warnAboutMisplacedAnalyzerRules(optInRules: [String], ruleList: RuleList) {
        let analyzerRules = ruleList.rules
            .filter { $0.value.self is any AnalyzerRule.Type }
            .map(\.key)
        Set(analyzerRules).intersection(optInRules)
            .sorted()
            .forEach {
                SwiftiomaticError.genericWarning(
                    """
                    '\($0)' should be listed in the 'analyzer_rules' configuration section \
                    for more clarity as it is only run by the analyze command.
                    """,
                ).print()
            }
    }
}
