import Foundation
import SwiftiomaticSyntax

struct LeadingWhitespaceRule: Rule {
  static let id = "leading_whitespace"
  static let name = "Leading Whitespace"
  static let summary = "Files should not contain leading whitespace"
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("//")
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("\n//"),
      Example(" //"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("\n //", shouldTestMultiByteOffsets: false): Example("//")
    ]
  }

  var options = SeverityOption<Self>(.warning)

  func validate(file: SwiftSource) -> [RuleViolation] {
    let countOfLeadingWhitespace = file.contents.countOfLeadingCharacters(
      in: .whitespacesAndNewlines,
    )
    if countOfLeadingWhitespace == 0 {
      return []
    }

    return [
      RuleViolation(
        ruleType: Self.self,
        severity: options.severity,
        location: Location(file: file.path, line: 1),
      )
    ]
  }

  func correct(file: SwiftSource) -> Int {
    let whitespaceAndNewline = CharacterSet.whitespacesAndNewlines
    let spaceCount = file.contents.countOfLeadingCharacters(in: whitespaceAndNewline)
    guard spaceCount > 0,
      let firstLineRange = file.lines.first?.range,
      file.ruleEnabled(violatingRanges: [firstLineRange], for: self).isNotEmpty
    else {
      return 0
    }

    let indexEnd =
      file.contents.index(
        file.contents.startIndex,
        offsetBy: spaceCount,
        limitedBy: file.contents.endIndex,
      ) ?? file.contents.endIndex
    file.write(String(file.contents[indexEnd...]))
    return 1
  }
}
