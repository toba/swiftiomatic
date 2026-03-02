import Foundation
import SwiftIDEUtils

struct PeriodSpacingRule: SyntaxOnlyRule, SubstitutionCorrectableRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PeriodSpacingConfiguration()

  func violationRanges(in file: SwiftSource) -> [Range<String.Index>] {
    let str = file.stringView.string
    return file.syntaxClassifications
      .filter(\.kind.isComment)
      .map { $0.range.toSourceKitByteRange() }
      .compactMap { (range: ByteRange) -> [Range<String.Index>]? in
        guard let searchRange = file.stringView.byteRangeToStringRange(range)
        else { return nil }
        return regex(#"\.[ \t]{2,}"#)
          .matches(in: str, range: searchRange)
          .compactMap { result -> Range<String.Index>? in
            // Skip the period and first space, keep remaining extra spaces
            let matchRange = result.range
            let skipIndex = str.index(matchRange.lowerBound, offsetBy: 2)
            guard skipIndex <= matchRange.upperBound else { return nil }
            return skipIndex..<matchRange.upperBound
          }
      }
      .flatMap(\.self)
  }

  func validate(file: SwiftSource) -> [RuleViolation] {
    violationRanges(in: file).map { range in
      RuleViolation(
        configuration: Self.configuration,
        severity: options.severity,
        location: Location(file: file, stringIndex: range.lowerBound),
      )
    }
  }

  func substitution(for violationRange: Range<String.Index>, in _: SwiftSource)
    -> (Range<String.Index>, String)?
  {
    (violationRange, "")
  }
}
