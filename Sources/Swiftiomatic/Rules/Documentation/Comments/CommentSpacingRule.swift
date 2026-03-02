import Foundation
import SwiftIDEUtils

struct CommentSpacingRule: SyntaxOnlyRule, SubstitutionCorrectableRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = CommentSpacingConfiguration()

  func violationRanges(in file: SwiftSource) -> [Range<String.Index>] {
    // Find all comment tokens in the file and regex search them for violations
    let str = file.stringView.string
    return file.syntaxClassifications
      .filter(\.kind.isComment)
      .map { $0.range.toSourceKitByteRange() }
      .compactMap { (range: ByteRange) -> [Range<String.Index>]? in
        guard let searchRange = file.stringView.byteRangeToStringRange(range)
        else { return nil }
        // Look for 2+ slash characters followed immediately by
        // a non-colon, non-whitespace character or by a colon
        // followed by a non-whitespace character other than #
        return regex(#"^(?:\/){2,}+(?:[^\s:]|:[^\s#])"#)
          .matches(in: str, range: searchRange)
          .map { result in
            // Zero-length range at the last character of the match
            // (directly before the first non-slash, non-whitespace character)
            let violationIndex = str.index(before: result.range.upperBound)
            return violationIndex..<violationIndex
          }
      }
      .flatMap(\.self)
  }

  func validate(file: SwiftSource) -> [RuleViolation] {
    violationRanges(in: file).map { range in
      RuleViolation(
        ruleDescription: Self.description,
        severity: options.severity,
        location: Location(file: file, stringIndex: range.lowerBound),
      )
    }
  }

  func substitution(for violationRange: Range<String.Index>, in _: SwiftSource)
    -> (Range<String.Index>, String)?
  {
    (violationRange, " ")
  }
}
