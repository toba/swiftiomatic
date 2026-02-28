import Foundation

func regex(
  _ pattern: String,
  options: NSRegularExpression.Options? = nil,
) -> RegularExpression {
  // all patterns used for regular expressions in SwiftLint are string literals which have been
  // confirmed to work, so it's ok to force-try here.

  // sm:disable:next force_try
  return try! .cached(pattern: pattern, options: options)
}

extension SwiftSource {
  func match(
    pattern: String, with syntaxKinds: [SourceKitSyntaxKind],
    range: Range<String.Index>? = nil
  ) -> [Range<String.Index>] {
    match(pattern: pattern, range: range)
      .filter { $0.1 == syntaxKinds }
      .map(\.0)
  }

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

  /// This function returns only matches that are not contained in a syntax kind
  /// specified.
  ///
  /// - parameter pattern: regex pattern to be matched inside file.
  /// - parameter excludingSyntaxKinds: syntax kinds the matches to be filtered
  /// when inside them.
  ///
  /// - returns: An array of `Range<String.Index>` objects consisting of regex matches inside
  /// file contents.
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

  func ruleEnabled(
    violatingRange: Range<String.Index>, for rule: some Rule
  ) -> Range<String.Index>? {
    ruleEnabled(violatingRanges: [violatingRange], for: rule).first
  }

  // MARK: - NSRange overloads (for rules using SourceKit/Line ranges)

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

  func ruleEnabled(violatingRange: NSRange, for rule: some Rule) -> NSRange? {
    ruleEnabled(violatingRanges: [violatingRange], for: rule).first
  }

  func contents(for token: ResolvedSyntaxToken) -> String? {
    stringView.substringWithByteRange(token.range)
  }
}
