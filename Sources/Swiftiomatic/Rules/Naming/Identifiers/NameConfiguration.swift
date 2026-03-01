import Foundation

struct NameConfiguration<Parent: Rule>: RuleOptions, InlinableOption {
  typealias SeverityConfig = SeverityConfiguration<Parent>
  typealias SeverityLevels = SeverityLevelsConfiguration<Parent>
  typealias StartWithLowercaseConfiguration = OptionSeverityConfiguration<Parent>

  @ConfigurationElement(key: "min_length")
  private(set) var minLength = SeverityLevels(warning: 0, error: 0)
  @ConfigurationElement(key: "max_length")
  private(set) var maxLength = SeverityLevels(warning: 0, error: 0)
  @ConfigurationElement(key: "excluded")
  private(set) var excludedCachedRegexs = Set<CachedRegex>()
  @ConfigurationElement(key: "allowed_symbols")
  private(set) var allowedSymbols = Set<String>()
  @ConfigurationElement(key: "unallowed_symbols_severity")
  private(set) var unallowedSymbolsSeverity = SeverityConfig.error
  @ConfigurationElement(key: "validates_start_with_lowercase")
  private(set) var validatesStartWithLowercase = StartWithLowercaseConfiguration.error

  var minLengthThreshold: Int {
    max(minLength.warning, minLength.error ?? minLength.warning)
  }

  var maxLengthThreshold: Int {
    min(maxLength.warning, maxLength.error ?? maxLength.warning)
  }

  var allowedSymbolsAndAlphanumerics: CharacterSet {
    CharacterSet(charactersIn: allowedSymbols.joined()).union(.alphanumerics)
  }

  init(
    minLengthWarning: Int,
    minLengthError: Int,
    maxLengthWarning: Int,
    maxLengthError: Int,
    excluded: [String] = [],
    allowedSymbols: [String] = [],
    unallowedSymbolsSeverity: SeverityConfig = .error,
    validatesStartWithLowercase: StartWithLowercaseConfiguration = .error,
  ) {
    minLength = SeverityLevels(warning: minLengthWarning, error: minLengthError)
    maxLength = SeverityLevels(warning: maxLengthWarning, error: maxLengthError)
    excludedCachedRegexs = Set(
      excluded.compactMap {
        try? CachedRegex(pattern: "^\($0)$")
      },
    )
    self.allowedSymbols = Set(allowedSymbols)
    self.unallowedSymbolsSeverity = unallowedSymbolsSeverity
    self.validatesStartWithLowercase = validatesStartWithLowercase
  }

  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    if let minLengthConfig = configuration[$minLength.key] {
      if let dict = minLengthConfig as? [String: Any] {
        try minLength.apply(configuration: dict)
      } else if let array = minLengthConfig as? [Int] {
        try minLength.apply(configuration: ["_values": array])
      }
    }
    if let maxLengthConfig = configuration[$maxLength.key] {
      if let dict = maxLengthConfig as? [String: Any] {
        try maxLength.apply(configuration: dict)
      } else if let array = maxLengthConfig as? [Int] {
        try maxLength.apply(configuration: ["_values": array])
      }
    }
    if let excluded = [String].array(of: configuration[$excludedCachedRegexs.key]) {
      excludedCachedRegexs = Set(
        excluded.compactMap {
          try? CachedRegex(pattern: "^\($0)$")
        },
      )
    }
    if let allowedSymbols = [String].array(of: configuration[$allowedSymbols.key]) {
      self.allowedSymbols = Set(allowedSymbols)
    }
    if let severityString = configuration[$unallowedSymbolsSeverity.key] as? String {
      try self.unallowedSymbolsSeverity.apply(configuration: ["severity": severityString])
    }
    if let lowercaseString = configuration[$validatesStartWithLowercase.key] as? String {
      try self.validatesStartWithLowercase.apply(configuration: ["severity": lowercaseString])
    }
  }
}

extension NameConfiguration {
  func severity(forLength length: Int) -> Severity? {
    if let minError = minLength.error, length < minError {
      return .error
    }
    if let maxError = maxLength.error, length > maxError {
      return .error
    }
    if length < minLength.warning || length > maxLength.warning {
      return .warning
    }
    return nil
  }

  func containsOnlyAllowedCharacters(name: String) -> Bool {
    allowedSymbolsAndAlphanumerics.isSuperset(of: CharacterSet(charactersIn: name))
  }
}

// MARK: - `exclude` option extensions

extension NameConfiguration {
  func shouldExclude(name: String) -> Bool {
    excludedCachedRegexs.contains { $0.hasMatch(in: name) }
  }
}
