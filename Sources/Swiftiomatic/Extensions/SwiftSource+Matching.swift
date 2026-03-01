import Foundation

/// Creates or retrieves a cached regular expression for the given pattern
///
/// All patterns used here are compile-time verified string literals.
///
/// - Parameters:
///   - pattern: The regular expression pattern string.
///   - options: Optional ``NSRegularExpression/Options`` to apply.
func regex(
  _ pattern: String,
  options: NSRegularExpression.Options? = nil,
) -> CachedRegex {
  // all patterns used for regular expressions in Swiftiomatic are string literals which have been
  // confirmed to work, so it's ok to force-try here.

  // sm:disable:next force_try
  return try! .cached(pattern: pattern, options: options)
}

extension SwiftSource {
  /// Returns ranges where the pattern matches and the matched tokens have the expected syntax kinds
  ///
  /// - Parameters:
  ///   - pattern: Regular expression pattern to match.
  ///   - syntaxKinds: The exact sequence of syntax kinds the match must contain.
  ///   - range: Optional sub-range of the file to search within.
  func match(
    pattern: String, with syntaxKinds: [SourceKitSyntaxKind],
    range: Range<String.Index>? = nil
  ) -> [Range<String.Index>] {
    match(pattern: pattern, range: range)
      .filter { $0.1 == syntaxKinds }
      .map(\.0)
  }

  /// Returns all regex matches paired with the syntax kinds of each matched region
  ///
  /// - Parameters:
  ///   - pattern: Regular expression pattern to match.
  ///   - range: Optional sub-range of the file to search within.
  ///   - captureGroup: The capture group index whose range to return (0 for the full match).
  func match(pattern: String, range: Range<String.Index>? = nil, captureGroup: Int = 0) -> [(
    Range<String.Index>, [SourceKitSyntaxKind],
  )] {
    let contents = stringView
    let str = contents.string
    let searchRange = range ?? str.startIndex..<str.endIndex
    let syntax = syntaxMap
    return regex(pattern).matches(in: str, range: searchRange).compactMap { match in
      let matchRange = match.range
      let byteStart = str.utf8.distance(from: str.utf8.startIndex, to: matchRange.lowerBound)
      let byteEnd = str.utf8.distance(from: str.utf8.startIndex, to: matchRange.upperBound)
      let matchByteRange = ByteRange(
        location: ByteCount(byteStart), length: ByteCount(byteEnd - byteStart),
      )
      let groupRange: Range<String.Index>
      if captureGroup == 0 {
        groupRange = matchRange
      } else if let sub = match.output[captureGroup].substring {
        groupRange = sub.startIndex..<sub.endIndex
      } else {
        return nil
      }
      return (groupRange, syntax.tokens(inByteRange: matchByteRange).kinds)
    }
  }

  /// Returns matches that do not overlap with any of the excluded syntax kinds
  ///
  /// - Parameters:
  ///   - pattern: Regular expression pattern to match.
  ///   - syntaxKinds: Syntax kinds to exclude -- matches inside these kinds are filtered out.
  ///   - range: Optional sub-range of the file to search within.
  ///   - captureGroup: The capture group index whose range to return (0 for the full match).
  func match(
    pattern: String,
    excludingSyntaxKinds syntaxKinds: Set<SourceKitSyntaxKind>,
    range: Range<String.Index>? = nil,
    captureGroup: Int = 0,
  ) -> [Range<String.Index>] {
    match(pattern: pattern, range: range, captureGroup: captureGroup)
      .filter { syntaxKinds.isDisjoint(with: $0.1) }
      .map(\.0)
  }

  /// Filters violation ranges to only those where the rule is enabled by region annotations
  ///
  /// - Parameters:
  ///   - violatingRanges: Candidate violation ranges to filter.
  ///   - rule: The rule to check enablement for.
  func ruleEnabled(
    violatingRanges: [Range<String.Index>], for rule: some Rule
  ) -> [Range<String.Index>] {
    let fileRegions = regions()
    if fileRegions.isEmpty { return violatingRanges }
    return violatingRanges.filter { range in
      let region = fileRegions.first {
        $0.contains(Location(file: self, stringIndex: range.lowerBound))
      }
      return region?.isRuleEnabled(rule) ?? true
    }
  }

  /// Returns the range if the rule is enabled at that location, or `nil` if disabled
  ///
  /// - Parameters:
  ///   - violatingRange: The candidate violation range.
  ///   - rule: The rule to check enablement for.
  func ruleEnabled(
    violatingRange: Range<String.Index>, for rule: some Rule
  ) -> Range<String.Index>? {
    ruleEnabled(violatingRanges: [violatingRange], for: rule).first
  }

  // MARK: - NSRange overloads (mirrors Range<String.Index> versions above for SourceKit/Line ranges)

  /// Filters `NSRange` violation ranges to only those where the rule is enabled
  ///
  /// - Parameters:
  ///   - violatingRanges: Candidate violation ranges to filter.
  ///   - rule: The rule to check enablement for.
  func ruleEnabled(violatingRanges: [NSRange], for rule: some Rule) -> [NSRange] {
    let fileRegions = regions()
    if fileRegions.isEmpty { return violatingRanges }
    return violatingRanges.filter { range in
      let region = fileRegions.first {
        $0.contains(Location(file: self, characterOffset: range.location))
      }
      return region?.isRuleEnabled(rule) ?? true
    }
  }

  /// Returns the `NSRange` if the rule is enabled at that location, or `nil` if disabled
  ///
  /// - Parameters:
  ///   - violatingRange: The candidate violation range.
  ///   - rule: The rule to check enablement for.
  func ruleEnabled(violatingRange: NSRange, for rule: some Rule) -> NSRange? {
    ruleEnabled(violatingRanges: [violatingRange], for: rule).first
  }

  /// Extracts the string contents of a resolved syntax token from this file
  ///
  /// - Parameters:
  ///   - token: The ``ResolvedSyntaxToken`` whose byte range to extract.
  func contents(for token: ResolvedSyntaxToken) -> String? {
    stringView.substringWithByteRange(token.range)
  }
}
