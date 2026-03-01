import Foundation

struct FileHeaderConfiguration: SeverityBasedRuleConfiguration {
  typealias Parent = FileHeaderRule

  private static let fileNamePlaceholder = "CURRENT_FILENAME"

  @ConfigurationElement(key: "severity")
  var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "required_string")
  private var requiredString: String?
  @ConfigurationElement(key: "required_pattern")
  private var requiredPattern: String?
  @ConfigurationElement(key: "forbidden_string")
  private var forbiddenString: String?
  @ConfigurationElement(key: "forbidden_pattern")
  private var forbiddenPattern: String?

  private var _forbiddenRegex: CachedRegex?
  private var _requiredRegex: CachedRegex?

  // sm:disable:next force_try
  private static let defaultRegex = try! CachedRegex(
    pattern: "\\bCopyright\\b", options: [.caseInsensitive],
  )

  mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
    guard let configuration = configuration as? [String: String] else {
      throw .invalidConfiguration(ruleID: Parent.identifier)
    }

    // Cache the created regexes if possible.
    // If the pattern contains the CURRENT_FILENAME placeholder,
    // the regex will be recompiled for each validated file.
    if let requiredString = configuration[$requiredString.key] {
      self.requiredString = requiredString
      if !requiredString.contains(Self.fileNamePlaceholder) {
        _requiredRegex = try .from(
          pattern: CachedRegex.escapedPattern(for: requiredString),
          for: Parent.identifier,
        )
      }
    } else if let requiredPattern = configuration[$requiredPattern.key] {
      self.requiredPattern = requiredPattern
      if !requiredPattern.contains(Self.fileNamePlaceholder) {
        _requiredRegex = try .from(pattern: requiredPattern, for: Parent.identifier)
      }
    }

    if let forbiddenString = configuration[$forbiddenString.key] {
      self.forbiddenString = forbiddenString
      if !forbiddenString.contains(Self.fileNamePlaceholder) {
        _forbiddenRegex = try .from(
          pattern: CachedRegex.escapedPattern(for: forbiddenString),
          for: Parent.identifier,
        )
      }
    } else if let forbiddenPattern = configuration[$forbiddenPattern.key] {
      self.forbiddenPattern = forbiddenPattern
      if !forbiddenPattern.contains(Self.fileNamePlaceholder) {
        _forbiddenRegex = try .from(pattern: forbiddenPattern, for: Parent.identifier)
      }
    }

    if let severityString = configuration[$severityConfiguration.key] {
      try severityConfiguration.apply(configuration: ["severity": severityString])
    }
  }

  private func makeRegex(
    for file: SwiftSource,
    using pattern: String,
    escapeFileName: Bool,
  ) -> CachedRegex? {
    let replacedPattern =
      file.path.map { path in
        let fileName = path.bridge().lastPathComponent
        let escapedName =
          escapeFileName ? CachedRegex.escapedPattern(for: fileName) : fileName
        return pattern.replacingOccurrences(
          of: Self.fileNamePlaceholder,
          with: escapedName,
        )
      } ?? pattern
    return try? CachedRegex(pattern: replacedPattern)
  }

  private func regexFromString(for file: SwiftSource, using string: String)
    -> CachedRegex?
  {
    // For string matching, escape the pattern so it matches literally
    let escapedPattern = CachedRegex.escapedPattern(for: string)
    return makeRegex(for: file, using: escapedPattern, escapeFileName: false)
  }

  private func regexFromPattern(for file: SwiftSource, using pattern: String)
    -> CachedRegex?
  {
    makeRegex(for: file, using: pattern, escapeFileName: true)
  }

  func forbiddenRegex(for file: SwiftSource) -> CachedRegex? {
    if let cached = _forbiddenRegex {
      return cached
    }

    if let regex = forbiddenString.flatMap({ regexFromString(for: file, using: $0) }) {
      return regex
    }

    if let regex = forbiddenPattern.flatMap({ regexFromPattern(for: file, using: $0) }) {
      return regex
    }

    if requiredPattern == nil, requiredString == nil {
      return Self.defaultRegex
    }

    return nil
  }

  func requiredRegex(for file: SwiftSource) -> CachedRegex? {
    if let cached = _requiredRegex {
      return cached
    }

    if let regex = requiredString.flatMap({ regexFromString(for: file, using: $0) }) {
      return regex
    }

    return requiredPattern.flatMap { regexFromPattern(for: file, using: $0) }
  }
}
