import Foundation

package final class FormatRule: Hashable, Comparable, CustomStringConvertible, @unchecked Sendable {
    static let unnamedRule = "[unnamed rule]"

    private let fn: (Formatter) -> Void
    package fileprivate(set) var name = FormatRule.unnamedRule
    fileprivate(set) var index = 0
    let help: String
    let examples: String?
    let runOnceOnly: Bool
    let disabledByDefault: Bool
    let orderAfter: [FormatRule]
    let options: [String]
    let sharedOptions: [String]
    let deprecationMessage: String?

    /// Null rule, used for testing
    static let none: FormatRule = .init(help: "") { _ in
    } examples: {
        nil
    }

    package var isDeprecated: Bool {
        deprecationMessage != nil
    }

    package var description: String {
        name
    }

    init(
        help: String,
        deprecationMessage: String? = nil,
        runOnceOnly: Bool = false,
        disabledByDefault: Bool = false,
        orderAfter: [FormatRule] = [],
        options: [String] = [],
        sharedOptions: [String] = [],
        _ fn: @escaping (Formatter) -> Void,
        examples: () -> String?,
    ) {
        self.fn = fn
        self.help = help
        self.runOnceOnly = runOnceOnly
        self.disabledByDefault = disabledByDefault || deprecationMessage != nil
        self.orderAfter = orderAfter
        self.options = options
        self.sharedOptions = sharedOptions
        self.deprecationMessage = deprecationMessage
        self.examples = examples()
    }

    func apply(with formatter: Formatter) {
        formatter.currentRule = self
        fn(formatter)
        formatter.currentRule = nil
    }

    package static func == (lhs: FormatRule, rhs: FormatRule) -> Bool {
        lhs === rhs
    }

    package static func < (lhs: FormatRule, rhs: FormatRule) -> Bool {
        lhs.index < rhs.index
    }

    package func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

package let FormatRules = FormatRuleCatalog()

private let rulesByName: [String: FormatRule] = {
    var rules = [String: FormatRule]()
    for (name, rule) in ruleRegistry {
        rule.name = name
        rules[name] = rule
    }
    for rule in rules.values {
        assert(rule.name != "[unnamed rule]")
    }
    let values = rules.values.sorted(by: { $0.name < $1.name })
    for (index, value) in values.enumerated() {
        value.index = index * 10
    }
    var changedOrder = true
    while changedOrder {
        changedOrder = false
        for value in values {
            for rule in value.orderAfter {
                if rule.index >= value.index {
                    value.index = rule.index + 1
                    changedOrder = true
                }
            }
        }
    }
    return rules
}()

private func allRules(except rules: [FormatRule]) -> [FormatRule] {
    _allRules.filter { !rules.contains($0) }
}

private let _allRules = rulesByName.sorted(by: { $0.key < $1.key }).map(\.value)
private let _deprecatedRules = _allRules.filter(\.isDeprecated)
private let _disabledByDefault = _allRules.filter(\.disabledByDefault)
private let _defaultRules = allRules(except: _disabledByDefault)

extension FormatRuleCatalog {
    /// A Dictionary of rules by name
    package var byName: [String: FormatRule] {
        rulesByName
    }

    /// All rules
    package var all: [FormatRule] {
        _allRules
    }

    /// Default active rules
    package var `default`: [FormatRule] {
        _defaultRules
    }

    /// Rules that are disabled by default
    var disabledByDefault: [FormatRule] {
        _disabledByDefault
    }

    /// Rules that are deprecated
    var deprecated: [FormatRule] {
        _deprecatedRules
    }

    /// Just the specified rules
    package func named(_ names: [String]) -> [FormatRule] {
        Array(names.sorted().compactMap { rulesByName[$0] })
    }

    /// All rules except those specified
    func all(except rules: [FormatRule]) -> [FormatRule] {
        allRules(except: rules)
    }
}

extension FormatRuleCatalog {
    /// Get all format options used by a given set of rules
    func optionsForRules(_ rules: [FormatRule]) -> [String] {
        var options = Set<String>()
        for rule in rules {
            options.formUnion(rule.options + rule.sharedOptions)
        }
        return options.sorted()
    }

    /// Get shared-only options for a given set of rules
    func sharedOptionsForRules(_ rules: [FormatRule]) -> [String] {
        var options = Set<String>()
        var sharedOptions = Set<String>()
        for rule in rules {
            options.formUnion(rule.options)
            sharedOptions.formUnion(rule.sharedOptions)
        }
        sharedOptions.subtract(options)
        return sharedOptions.sorted()
    }
}

package struct FormatRuleCatalog {
    fileprivate init() {}
}
