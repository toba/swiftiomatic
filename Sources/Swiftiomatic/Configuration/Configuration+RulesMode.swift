extension Configuration {
    /// Return the rule for the specified ID, if configured in this configuration
    ///
    /// - Parameters:
    ///   - ruleID: The identifier for the rule to look up.
    /// - Returns: The rule for the specified ID, if configured in this configuration.
    func configuredRule(forID ruleID: String) -> (any Rule)? {
        rules.first { rule in
            type(of: rule).identifier == ruleID
        }
    }

    /// Represents how a ``Configuration`` selects which rules are active
    public enum RulesMode: Equatable, Sendable {
        /// Enable all non-``OptInRule`` rules minus `disabled`, plus `optIn`
        case defaultConfiguration(disabled: Set<String>, optIn: Set<String>)

        /// Only enable the rules explicitly listed in the configuration files
        case onlyConfiguration(Set<String>)

        /// Only enable the rule(s) explicitly listed on the command line (and their aliases)
        case onlyCommandLine(Set<String>)

        /// Enable all available rules
        case allCommandLine

        init(
            enableAllRules: Bool,
            onlyRule: [String],
            onlyRules: [String],
            optInRules: [String],
            disabledRules: [String],
            analyzerRules: [String],
        ) throws {
            func warnAboutDuplicates(in identifiers: [String]) {
                if Set(identifiers).count != identifiers.count {
                    let duplicateRules = identifiers.reduce(into: [String: Int]()) {
                        $0[
                            $1,
                            default: 0,
                        ] += 1
                    }
                    .filter { $0.1 > 1 }
                    for duplicateRule in duplicateRules {
                        SwiftiomaticError.listedMultipleTime(
                            ruleID: duplicateRule.0,
                            times: duplicateRule.1,
                        )
                        .print()
                    }
                }
            }

            if enableAllRules {
                self = .allCommandLine
            } else if onlyRule.isNotEmpty {
                self = .onlyCommandLine(Set(onlyRule))
            } else if onlyRules.isNotEmpty {
                if disabledRules.isNotEmpty || optInRules.isNotEmpty {
                    throw SwiftiomaticError.genericWarning(
                        "'\(Configuration.Key.disabledRules.rawValue)' or "
                            + "'\(Configuration.Key.optInRules.rawValue)' cannot be used in combination "
                            + "with '\(Configuration.Key.onlyRules.rawValue)'",
                    )
                }

                warnAboutDuplicates(in: onlyRules + analyzerRules)
                self = .onlyConfiguration(Set(onlyRules + analyzerRules))
            } else {
                warnAboutDuplicates(in: disabledRules)

                let effectiveOptInRules: [String]
                if optInRules.contains(RuleIdentifier.all.stringRepresentation) {
                    let allOptInRules = RuleRegistry.shared.list.rules
                        .compactMap { ruleID, ruleType in
                            ruleType.isOptIn
                                && !ruleType.runsWithCompilerArguments ? ruleID : nil
                        }
                    effectiveOptInRules = Array(Set(allOptInRules + optInRules))
                } else {
                    effectiveOptInRules = optInRules
                }

                let effectiveAnalyzerRules: [String]
                if analyzerRules.contains(RuleIdentifier.all.stringRepresentation) {
                    let allAnalyzerRules = RuleRegistry.shared.list.rules
                        .compactMap { ruleID, ruleType in
                            ruleType.runsWithCompilerArguments ? ruleID : nil
                        }
                    effectiveAnalyzerRules = allAnalyzerRules
                } else {
                    effectiveAnalyzerRules = analyzerRules
                }

                warnAboutDuplicates(in: effectiveOptInRules + effectiveAnalyzerRules)
                self = .defaultConfiguration(
                    disabled: Set(disabledRules),
                    optIn: Set(effectiveOptInRules + effectiveAnalyzerRules),
                )
            }
        }

        /// Return a copy with all rule identifiers resolved through the alias resolver
        ///
        /// - Parameters:
        ///   - aliasResolver: A closure that maps deprecated aliases to canonical identifiers.
        /// - Returns: A new ``RulesMode`` with all identifiers resolved.
        func applied(aliasResolver: (String) -> String) -> Self {
            switch self {
                case let .defaultConfiguration(disabled, optIn):
                    return .defaultConfiguration(
                        disabled: Set(disabled.map(aliasResolver)),
                        optIn: Set(optIn.map(aliasResolver)),
                    )

                case let .onlyConfiguration(onlyRules):
                    return .onlyConfiguration(Set(onlyRules.map(aliasResolver)))

                case let .onlyCommandLine(onlyRules):
                    return .onlyCommandLine(Set(onlyRules.map(aliasResolver)))

                case .allCommandLine:
                    return .allCommandLine
            }
        }
    }
}
