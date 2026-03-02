import Foundation

struct LeadingWhitespaceRule: CorrectableRule, SyntaxOnlyRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LeadingWhitespaceConfiguration()

  func validate(file: SwiftSource) -> [RuleViolation] {
    let countOfLeadingWhitespace = file.contents.countOfLeadingCharacters(
      in: .whitespacesAndNewlines,
    )
    if countOfLeadingWhitespace == 0 {
      return []
    }

    return [
      RuleViolation(
        ruleDescription: Self.description,
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
