import Foundation
import SwiftIDEUtils

struct PeriodSpacingRule: SyntaxOnlyRule, SubstitutionCorrectableRule {
    static let id = "period_spacing"
    static let name = "Period Spacing"
    static let summary = "Periods should not be followed by more than one space"
    static let isCorrectable = true
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("let pi = 3.2"),
              Example("let pi = Double.pi"),
              Example("let pi = Double. pi"),
              Example("let pi = Double.  pi"),
              Example("// A. Single."),
              Example("///   - code: Identifier of the error. Integer."),
              Example(
                """
                // value: Multiline.
                //        Comment.
                """,
              ),
              Example(
                """
                /**
                Sentence ended in period.

                - Sentence 2 new line characters after.
                **/
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                "/* Only god knows why. ↓ This symbol does nothing. */",
                shouldTestWrappingInComment: false,
              ),
              Example(
                "// Only god knows why. ↓ This symbol does nothing.",
                shouldTestWrappingInComment: false,
              ),
              Example("// Single. Double. ↓ End.", shouldTestWrappingInComment: false),
              Example("// Single. Double. ↓ Triple. ↓  End.", shouldTestWrappingInComment: false),
              Example("// Triple. ↓  Quad. ↓   End.", shouldTestWrappingInComment: false),
              Example(
                "///   - code: Identifier of the error. ↓ Integer.",
                shouldTestWrappingInComment: false,
              ),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("/* Why. ↓ Symbol does nothing. */"): Example(
                "/* Why. Symbol does nothing. */",
              ),
              Example("// Why. ↓ Symbol does nothing."): Example("// Why. Symbol does nothing."),
              Example("// Single. Double. ↓ End."): Example("// Single. Double. End."),
              Example("// Single. Double. ↓ Triple. ↓  End."): Example(
                "// Single. Double. Triple. End.",
              ),
              Example("// Triple. ↓  Quad. ↓   End."): Example("// Triple. Quad. End."),
              Example("///   - code: Identifier. ↓ Integer."): Example(
                "///   - code: Identifier. Integer.",
              ),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

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
        ruleType: Self.self,
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
