import Foundation
import SwiftIDEUtils

struct CommentSpacingRule: SyntaxOnlyRule, SubstitutionCorrectableRule {
    static let id = "comment_spacing"
    static let name = "Comment Spacing"
    static let summary = "Prefer at least one space after slashes for comments"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                // This is a comment
                """,
              ),
              Example(
                """
                /// Triple slash comment
                """,
              ),
              Example(
                """
                // Multiline double-slash
                // comment
                """,
              ),
              Example(
                """
                /// Multiline triple-slash
                /// comment
                """,
              ),
              Example(
                """
                /// Multiline triple-slash
                ///   - This is indented
                """,
              ),
              Example(
                """
                // - MARK: Mark comment
                """,
              ),
              Example(
                """
                //: Swift Playground prose section
                """,
              ),
              Example(
                """
                ///////////////////////////////////////////////
                // Comment with some lines of slashes boxing it
                ///////////////////////////////////////////////
                """,
              ),
              Example(
                """
                //:#localized(key: "SwiftPlaygroundLocalizedProse")
                """,
              ),
              Example(
                """
                /* Asterisk comment */
                """,
              ),
              Example(
                """
                /*
                    Multiline asterisk comment
                */
                """,
              ),
              Example(
                """
                /*:
                    Multiline Swift Playground prose section
                */
                """,
              ),
              Example(
                """
                /*#-editable-code Swift Playground editable area*/default/*#-end-editable-code*/
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                //↓Something
                """,
              ),
              Example(
                """
                //↓MARK
                """,
              ),
              Example(
                """
                //↓👨‍👨‍👦‍👦Something
                """,
              ),
              Example(
                """
                func a() {
                    //↓This needs refactoring
                    print("Something")
                }
                //↓We should improve above function
                """,
              ),
              Example(
                """
                ///↓This is a comment
                """,
              ),
              Example(
                """
                /// Multiline triple-slash
                ///↓This line is incorrect, though
                """,
              ),
              Example(
                """
                //↓- MARK: Mark comment
                """,
              ),
              Example(
                """
                //:↓Swift Playground prose section
                """,
              ),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("//↓Something"): Example("// Something"),
              Example("//↓- MARK: Mark comment"): Example("// - MARK: Mark comment"),
              Example(
                """
                /// Multiline triple-slash
                ///↓This line is incorrect, though
                """,
              ): Example(
                """
                /// Multiline triple-slash
                /// This line is incorrect, though
                """,
              ),
              Example(
                """
                func a() {
                    //↓This needs refactoring
                    print("Something")
                }
                //↓We should improve above function
                """,
              ): Example(
                """
                func a() {
                    // This needs refactoring
                    print("Something")
                }
                // We should improve above function
                """,
              ),
            ]
    }
  var options = SeverityOption<Self>(.warning)

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
        ruleType: Self.self,
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
