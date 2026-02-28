import Foundation
import Synchronization

extension Configuration {
    final class RuleSelection {
        // MARK: - Properties

        let allRulesWrapped: [ConfiguredRule]
        let mode: RulesMode
        private let aliasResolver: (String) -> String

        private var invalidRuleIdsWarnedAbout: Set<String> = []
        private var validRuleIdentifiers: Set<String> {
            Set(allRulesWrapped.map { type(of: $0.rule).identifier })
        }

        private struct RulesBox: @unchecked Sendable {
            var rules: [any Rule]?
        }

        private let cachedResultingRules = Mutex(RulesBox())

        /// All rules enabled in this configuration,
        /// derived from rule mode (only / optIn - disabled) & existing rules
        var resultingRules: [any Rule] {
            return cachedResultingRules.withLock { box in
                if let rules = box.rules { return rules }
                let rules = computeResultingRules()
                box.rules = rules
                return rules
            }
        }

        private func computeResultingRules() -> [any Rule] {
            var resultingRules = [any Rule]()
            switch mode {
                case .allCommandLine:
                    resultingRules = allRulesWrapped.map(\.rule)

                case let .onlyConfiguration(onlyRulesRuleIdentifiers),
                     let .onlyCommandLine(onlyRulesRuleIdentifiers):
                    let onlyRulesRuleIdentifiers = validate(
                        ruleIds: onlyRulesRuleIdentifiers, valid: validRuleIdentifiers,
                    )
                    resultingRules = allRulesWrapped.filter { tuple in
                        onlyRulesRuleIdentifiers.contains(type(of: tuple.rule).identifier)
                    }.map(\.rule)

                case var .defaultConfiguration(disabledRuleIdentifiers, optInRuleIdentifiers):
                    disabledRuleIdentifiers = validate(
                        ruleIds: disabledRuleIdentifiers, valid: validRuleIdentifiers,
                    )
                    optInRuleIdentifiers = validate(
                        optInRuleIds: optInRuleIdentifiers, valid: validRuleIdentifiers,
                    )
                    resultingRules = allRulesWrapped.filter { tuple in
                        let id = type(of: tuple.rule).identifier
                        return !disabledRuleIdentifiers.contains(id)
                            && (!(tuple.rule is any OptInRule) || optInRuleIdentifiers.contains(id))
                    }.map(\.rule)
            }

            // Sort by name
            resultingRules = resultingRules.sorted {
                type(of: $0).identifier < type(of: $1).identifier
            }

            return resultingRules
        }

        lazy var disabledRuleIdentifiers: [String] = {
            switch mode {
                case let .defaultConfiguration(disabled, _):
                    return validate(ruleIds: disabled, valid: validRuleIdentifiers, silent: true)
                        .sorted(by: <)

                case let .onlyConfiguration(onlyRules), let .onlyCommandLine(onlyRules):
                    return validate(
                        ruleIds: Set(
                            allRulesWrapped
                                .map { type(of: $0.rule).identifier }
                                .filter { !onlyRules.contains($0) },
                        ),
                        valid: validRuleIdentifiers,
                        silent: true,
                    ).sorted(by: <)

                case .allCommandLine:
                    return []
            }
        }()

        // MARK: - Initializers

        init(
            mode: RulesMode,
            allRulesWrapped: [ConfiguredRule],
            aliasResolver: @escaping (String) -> String,
        ) {
            self.allRulesWrapped = allRulesWrapped
            self.aliasResolver = aliasResolver
            self.mode = mode.applied(aliasResolver: aliasResolver)
        }

        // MARK: - Methods: Validation

        private func validate(optInRuleIds: Set<String>, valid: Set<String>) -> Set<String> {
            validate(
                ruleIds: optInRuleIds,
                valid: valid.union([RuleIdentifier.all.stringRepresentation]),
            )
        }

        private func validate(ruleIds: Set<String>, valid: Set<String>,
                              silent: Bool = false) -> Set<
            String,
        > {
            // Process invalid rule identifiers
            if !silent {
                let invalidRuleIdentifiers = ruleIds.subtracting(valid)
                if !invalidRuleIdentifiers.isEmpty {
                    for invalidRuleIdentifier in invalidRuleIdentifiers
                        .subtracting(invalidRuleIdsWarnedAbout)
                    {
                        invalidRuleIdsWarnedAbout.insert(invalidRuleIdentifier)
                        queuedPrintError(
                            "warning: '\(invalidRuleIdentifier)' is not a valid rule identifier",
                        )
                    }

                    queuedPrintError(
                        "Valid rule identifiers:\n\(valid.sorted().joined(separator: "\n"))",
                    )
                }
            }

            // Return valid rule identifiers
            return ruleIds.intersection(valid)
        }

    }
}

