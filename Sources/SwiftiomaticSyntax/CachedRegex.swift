package import Foundation
import Synchronization

// MARK: - CachedRegex (Swift Regex)

package struct CachedRegex: Hashable, Comparable, ExpressibleByStringLiteral, @unchecked Sendable {
  package let regex: Regex<AnyRegexOutput>
  package let pattern: String
  private let optionsRaw: UInt
  package let numberOfCaptureGroups: Int

  package init(pattern: String, options: NSRegularExpression.Options? = nil) throws {
    let opts = options ?? [.anchorsMatchLines, .dotMatchesLineSeparators]
    self.pattern = pattern
    optionsRaw = opts.rawValue
    regex = try Self.compileRegex(pattern: pattern, options: opts)
    numberOfCaptureGroups =
      (try? NSRegularExpression(pattern: pattern)).map(\.numberOfCaptureGroups) ?? 0
  }

  package init(stringLiteral value: String) {
    // sm:disable:next force_try
    try! self.init(pattern: value)
  }

  package static func from(
    pattern: String,
    options: NSRegularExpression.Options? = nil,
    for ruleID: String,
  ) throws(SwiftiomaticError) -> Self {
    do {
      return try Self(pattern: pattern, options: options)
    } catch {
      throw .invalidRegexPattern(ruleID: ruleID, pattern: pattern)
    }
  }

  // MARK: Hashable / Comparable

  package func hash(into hasher: inout Hasher) {
    hasher.combine(pattern)
    hasher.combine(optionsRaw)
  }

  package static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.pattern == rhs.pattern && lhs.optionsRaw == rhs.optionsRaw
  }

  package static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.pattern < rhs.pattern
  }

  // MARK: Matching

  package func firstMatch(in string: String) -> Regex<AnyRegexOutput>.Match? {
    string.firstMatch(of: regex)
  }

  package func firstMatch(in string: Substring) -> Regex<AnyRegexOutput>.Match? {
    string.firstMatch(of: regex)
  }

  package func hasMatch(in string: String) -> Bool {
    string.firstMatch(of: regex) != nil
  }

  package func hasMatch(in string: String, range nsRange: NSRange) -> Bool {
    guard let range = Range(nsRange, in: string) else { return false }
    return string[range].firstMatch(of: regex) != nil
  }

  package func firstMatch(in string: String, range nsRange: NSRange) -> Regex<AnyRegexOutput>.Match? {
    guard let range = Range(nsRange, in: string) else { return nil }
    return string[range].firstMatch(of: regex)
  }

  package func matches(in string: String) -> [Regex<AnyRegexOutput>.Match] {
    Array(string.matches(of: regex))
  }

  package func matches(in string: String, range nsRange: NSRange) -> [Regex<AnyRegexOutput>.Match] {
    guard let range = Range(nsRange, in: string) else { return [] }
    return Array(string[range].matches(of: regex))
  }

  package func firstMatch(in string: String, range: Range<String.Index>) -> Regex<AnyRegexOutput>.Match? {
    string[range].firstMatch(of: regex)
  }

  package func matches(in string: String, range: Range<String.Index>) -> [Regex<AnyRegexOutput>.Match] {
    Array(string[range].matches(of: regex))
  }

  package func matches(in stringView: StringView) -> [Regex<AnyRegexOutput>.Match] {
    matches(in: stringView.string, range: stringView.range)
  }

  package func matches(in file: SwiftSource) -> [Regex<AnyRegexOutput>.Match] {
    matches(in: file.stringView)
  }

  /// Closure-based replacement within a specific range.
  package func replacing(
    in string: String,
    range nsRange: NSRange,
    with replacement: (Regex<AnyRegexOutput>.Match) -> String,
  ) -> String {
    guard let range = Range(nsRange, in: string) else { return string }
    return replacing(in: string, range: range, with: replacement)
  }

  /// Closure-based replacement within a specific `Range<String.Index>`.
  package func replacing(
    in string: String,
    range: Range<String.Index>,
    with replacement: (Regex<AnyRegexOutput>.Match) -> String,
  ) -> String {
    let substring = string[range]
    let matchResults = substring.matches(of: regex)
    guard matchResults.isNotEmpty else { return string }

    var result = string
    // Process matches in reverse to preserve offsets
    for match in matchResults.reversed() {
      let matchRange = match.range
      let replacementText = replacement(match)
      result.replaceSubrange(matchRange, with: replacementText)
    }
    return result
  }

  package static func escapedPattern(for string: String) -> String {
    NSRegularExpression.escapedPattern(for: string)
  }

  // MARK: Cache

  private struct RegexCacheKey: Hashable {
    let pattern: String
    let optionsRaw: UInt
  }

  private static let regexCache = Mutex([RegexCacheKey: CachedRegex]())

  package static func cached(pattern: String, options: NSRegularExpression.Options? = nil) throws
    -> CachedRegex
  {
    let opts = options ?? [.anchorsMatchLines, .dotMatchesLineSeparators]
    let key = RegexCacheKey(pattern: pattern, optionsRaw: opts.rawValue)
    return try regexCache.withLock { cache in
      if let result = cache[key] {
        return result
      }
      let result = try CachedRegex(pattern: pattern, options: opts)
      cache[key] = result
      return result
    }
  }

  // MARK: Compilation

  private static func compileRegex(
    pattern: String, options: NSRegularExpression.Options,
  ) throws -> Regex<AnyRegexOutput> {
    var flags = ""
    if options.contains(.anchorsMatchLines) { flags += "m" }
    if options.contains(.dotMatchesLineSeparators) { flags += "s" }
    if options.contains(.caseInsensitive) { flags += "i" }

    if options.contains(.ignoreMetacharacters) {
      let escaped = NSRegularExpression.escapedPattern(for: pattern)
      let fullPattern = flags.isEmpty ? escaped : "(?\(flags))\(escaped)"
      return try Regex(fullPattern)
    }

    let fullPattern = flags.isEmpty ? pattern : "(?\(flags))\(pattern)"
    return try Regex(fullPattern)
  }
}
