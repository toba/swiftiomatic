import Foundation
import SwiftiomaticSyntax

struct NameOptions<Parent: Rule>: RuleOptions, InlinableOption {
  typealias SeverityConfig = SeverityOption<Parent>
  typealias SeverityLevels = SeverityLevelsConfiguration<Parent>
  typealias StartWithLowercaseConfiguration = OptionSeverityOption<Parent>

  @OptionElement(key: "min_length")
  private(set) var minLength = SeverityLevels(warning: 0, error: 0)
  @OptionElement(key: "max_length")
  private(set) var maxLength = SeverityLevels(warning: 0, error: 0)
  @OptionElement(key: "excluded")
  private(set) var excludedCachedRegexs = Set<CachedRegex>()
  @OptionElement(key: "allowed_symbols")
  private(set) var allowedSymbols = Set<String>()
  @OptionElement(key: "unallowed_symbols_severity")
  private(set) var unallowedSymbolsSeverity = SeverityConfig.error
  @OptionElement(key: "validates_start_with_lowercase")
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
      try unallowedSymbolsSeverity.apply(configuration: ["severity": severityString])
    }
    if let lowercaseString = configuration[$validatesStartWithLowercase.key] as? String {
      try validatesStartWithLowercase.apply(configuration: ["severity": lowercaseString])
    }
  }
}

extension NameOptions {
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
    let allowed = allowedSymbolsAndAlphanumerics
    return name.unicodeScalars.allSatisfy { scalar in
      allowed.contains(scalar) || !scalar.isASCII
    }
  }
}

// MARK: - `exclude` option extensions

extension NameOptions {
  func shouldExclude(name: String) -> Bool {
    excludedCachedRegexs.contains { $0.hasMatch(in: name) }
  }
}
