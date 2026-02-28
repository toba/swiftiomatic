/// The configuration payload mapping an imported module to a set of modules that are allowed to be
/// transitively imported.
struct TransitiveModuleConfiguration<Parent: Rule>: Equatable, AcceptableByConfigurationElement {
    /// The module imported in a source file.
    let importedModule: String
    /// The set of modules that can be transitively imported by `importedModule`.
    let transitivelyImportedModules: [String]

    init(fromAny configuration: Any, context _: String) throws(Issue) {
        guard let configurationDict = configuration as? [String: Any],
              Set(configurationDict.keys) == ["module", "allowed_transitive_imports"],
              let importedModule = configurationDict["module"] as? String,
              let transitivelyImportedModules = configurationDict["allowed_transitive_imports"] as? [String]
        else {
            throw .invalidConfiguration(ruleID: Parent.identifier)
        }
        self.importedModule = importedModule
        self.transitivelyImportedModules = transitivelyImportedModules
    }

    func asOption() -> OptionType {
        .nest {
            importedModule => .list(transitivelyImportedModules.map { .string($0) })
        }
    }
}

struct UnusedImportConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "require_explicit_imports")
    private(set) var requireExplicitImports = false
    @ConfigurationElement(key: "allowed_transitive_imports")
    private(set) var allowedTransitiveImports = [TransitiveModuleConfiguration<Parent>]()
    /// A set of modules to never remove the imports of.
    @ConfigurationElement(key: "always_keep_imports")
    private(set) var alwaysKeepImports = [String]()
    typealias Parent = UnusedImportRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $requireExplicitImports.key.isEmpty {
            $requireExplicitImports.key = "require_explicit_imports"
        }
        if $allowedTransitiveImports.key.isEmpty {
            $allowedTransitiveImports.key = "allowed_transitive_imports"
        }
        if $alwaysKeepImports.key.isEmpty {
            $alwaysKeepImports.key = "always_keep_imports"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$requireExplicitImports.key] {
            try requireExplicitImports.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$allowedTransitiveImports.key] {
            try allowedTransitiveImports.apply(value, ruleID: Parent.identifier)
        }
        if let value = configuration[$alwaysKeepImports.key] {
            try alwaysKeepImports.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}
