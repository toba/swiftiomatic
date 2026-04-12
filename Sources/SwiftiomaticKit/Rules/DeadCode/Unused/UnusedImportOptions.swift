import SwiftiomaticSyntax

/// The configuration payload mapping an imported module to a set of modules that are allowed to be
/// transitively imported.
struct TransitiveModuleOptions<Parent: Rule>: Equatable, AcceptableByOptionElement {
  /// The module imported in a source file.
  let importedModule: String
  /// The set of modules that can be transitively imported by `importedModule`.
  let transitivelyImportedModules: [String]

  init(fromAny configuration: Any, context _: String) throws(SwiftiomaticError) {
    guard let configurationDict = configuration as? [String: Any],
      Set(configurationDict.keys) == ["module", "allowed_transitive_imports"],
      let importedModule = configurationDict["module"] as? String,
      let transitivelyImportedModules =
        configurationDict["allowed_transitive_imports"] as? [String]
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

struct UnusedImportOptions: SeverityBasedRuleOptions {
  @OptionElement(key: "severity")
  var severityConfiguration = SeverityOption<Parent>.warning
  @OptionElement(key: "require_explicit_imports")
  private(set) var requireExplicitImports = false
  @OptionElement(key: "allowed_transitive_imports")
  private(set) var allowedTransitiveImports = [TransitiveModuleOptions<Parent>]()
  /// A set of modules to never remove the imports of.
  @OptionElement(key: "always_keep_imports")
  private(set) var alwaysKeepImports = [String]()
  typealias Parent = UnusedImportRule
  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    try applySeverityIfPresent(configuration)
    if let value = configuration[$requireExplicitImports.key] {
      try requireExplicitImports.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$allowedTransitiveImports.key] {
      try allowedTransitiveImports.apply(value, ruleID: Parent.identifier)
    }
    if let value = configuration[$alwaysKeepImports.key] {
      try alwaysKeepImports.apply(value, ruleID: Parent.identifier)
    }
    warnAboutUnknownKeys(in: configuration)
    validate()
  }
}
