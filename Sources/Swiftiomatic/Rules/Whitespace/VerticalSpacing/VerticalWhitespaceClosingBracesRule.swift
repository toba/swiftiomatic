import Foundation

struct VerticalWhitespaceClosingBracesRule: CorrectableRule, OptInRule {
  var configuration = VerticalWhitespaceClosingBracesConfiguration()

  static let description = RuleDescription(
    identifier: "vertical_whitespace_closing_braces",
    name: "Vertical Whitespace before Closing Braces",
    description: "Don't include vertical whitespace (empty line) before closing braces",
    nonTriggeringExamples: VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples
      .values.sorted() + VerticalWhitespaceClosingBracesRuleExamples.nonTriggeringExamples,
    triggeringExamples: Array(
      VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples.keys.sorted(),
    ),
    corrections: VerticalWhitespaceClosingBracesRuleExamples.violatingToValidExamples
      .removingViolationMarkers(),
  )

  private let pattern = "((?:\\n[ \\t]*)+)(\\n[ \\t]*[)}\\]])"
  private let trivialLinePattern = "((?:\\n[ \\t]*)+)(\\n[ \\t)}\\]]*$)"

  func validate(file: SwiftSource) -> [RuleViolation] {
    let pattern = configuration.onlyEnforceBeforeTrivialLines ? trivialLinePattern : pattern

    let patternRegex = regex(pattern)

    return file.violatingRanges(for: pattern).map { violationRange in
      let matchResult = patternRegex.firstMatch(
        in: file.contents, range: violationRange,
      )!
      let group1Sub = matchResult.output[1].substring!
      let violationIndex = file.contents.index(after: group1Sub.startIndex)

      return RuleViolation(
        ruleDescription: Self.description,
        severity: configuration.severityConfiguration.severity,
        location: Location(file: file, stringIndex: violationIndex),
      )
    }
  }

  func correct(file: SwiftSource) -> Int {
    let pattern = configuration.onlyEnforceBeforeTrivialLines ? trivialLinePattern : pattern
    let violatingRanges = file.ruleEnabled(
      violatingRanges: file.violatingRanges(for: pattern), for: self,
    )
    guard violatingRanges.isNotEmpty else {
      return 0
    }
    let patternRegex = regex(pattern)
    var fileContents = file.contents
    for violationRange in violatingRanges.reversed() {
      fileContents = patternRegex.replacing(in: fileContents, range: violationRange) { match in
        String(match.output[2].substring ?? "")
      }
    }
    file.write(fileContents)
    return violatingRanges.count
  }
}

extension SwiftSource {
  fileprivate func violatingRanges(for pattern: String) -> [Range<String.Index>] {
    match(pattern: pattern, excludingSyntaxKinds: SourceKitSyntaxKind.commentAndStringKinds)
  }
}
