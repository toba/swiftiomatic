import Foundation
import Synchronization

extension Configuration {
    /// Manages which rules are active based on the configured ``RulesMode``
    ///
    /// All mutable state is protected by `Mutex`, making concurrent access safe.
    public final class RuleSelection: @unchecked Sendable {
        // MARK: - Properties

        let allRulesWrapped: [ConfiguredRule]
        let mode: RulesMode
        private let aliasResolver: @Sendable (String) -> String
        private let validRuleIdentifiers: Set<String>

        private let invalidRuleIdsWarnedAbout = Mutex<Set<String>>([])
        private let cachedResultingRules = Mutex<[any Rule]?>(nil)

        /// All rules enabled in this configuration, derived from the ``RulesMode``
        var resultingRules: [any Rule] {
            cachedResultingRules.withLock { cached in
                if let rules = cached { return rules }
                let rules = computeResultingRules()
                cached = rules
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
                        let ruleType = type(of: tuple.rule)
                        let id = ruleType.identifier
                        return !disabledRuleIdentifiers.contains(id)
                            && ruleType.ruleScope == .lint
                            && (!ruleType.isOptIn || optInRuleIdentifiers.contains(id))
                    }.map(\.rule)
            }

            // Sort by name
            resultingRules = resultingRules.sorted {
                type(of: $0).identifier < type(of: $1).identifier
            }

            return resultingRules
        }

        // MARK: - Initializers

        init(
            mode: RulesMode,
            allRulesWrapped: [ConfiguredRule],
            aliasResolver: @escaping @Sendable (String) -> String,
        ) {
            self.allRulesWrapped = allRulesWrapped
            self.aliasResolver = aliasResolver
            validRuleIdentifiers = Set(allRulesWrapped.map { type(of: $0.rule).identifier })
            self.mode = mode.applied(aliasResolver: aliasResolver)
        }

        // MARK: - Methods: Validation

        private func validate(optInRuleIds: Set<String>, valid: Set<String>) -> Set<String> {
            validate(
                ruleIds: optInRuleIds,
                valid: valid.union([RuleIdentifier.all.stringRepresentation]),
            )
        }

        private func validate(
            ruleIds: Set<String>,
            valid: Set<String>,
            silent: Bool = false,
        ) -> Set<String> {
            // Process invalid rule identifiers
            if !silent {
                let invalidRuleIdentifiers = ruleIds.subtracting(valid)
                if !invalidRuleIdentifiers.isEmpty {
                    invalidRuleIdsWarnedAbout.withLock { warned in
                        for invalidRuleIdentifier in invalidRuleIdentifiers.subtracting(warned) {
                            warned.insert(invalidRuleIdentifier)
                            Console.printError(
                                "warning: '\(invalidRuleIdentifier)' is not a valid rule identifier",
                            )
                        }
                    }

                    Console.printError(
                        "Valid rule identifiers:\n\(valid.sorted().joined(separator: "\n"))",
                    )
                }
            }

            // Return valid rule identifiers
            return ruleIds.intersection(valid)
        }
    }
}
