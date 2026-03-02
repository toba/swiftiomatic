import Foundation

extension SwiftSource {
  fileprivate func violatingRanges(for pattern: String) -> [Range<String.Index>] {
    match(pattern: pattern, excludingSyntaxKinds: SourceKitSyntaxKind.commentAndStringKinds)
  }
}

struct VerticalWhitespaceOpeningBracesRule: Rule {
  var options = SeverityConfiguration<Self>(.warning)

  private let pattern = "([{(\\[][ \\t]*(?:[^\\n{]+ in[ \\t]*$)?)((?:\\n[ \\t]*)+)(\\n)"
}

extension VerticalWhitespaceOpeningBracesRule {
  static let configuration = VerticalWhitespaceOpeningBracesConfiguration()

  func validate(file: SwiftSource) -> [RuleViolation] {
    let patternRegex = regex(pattern)

    return file.violatingRanges(for: pattern).map { violationRange in
      let matchResult = patternRegex.firstMatch(
        in: file.contents, range: violationRange,
      )!
      let group2Sub = matchResult.output[2].substring!
      let violationIndex = file.contents.index(after: group2Sub.startIndex)

      return RuleViolation(
        configuration: Self.configuration,
        severity: options.severity,
        location: Location(file: file, stringIndex: violationIndex),
      )
    }
  }
}

extension VerticalWhitespaceOpeningBracesRule: CorrectableRule {
  func correct(file: SwiftSource) -> Int {
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
        let g1 = match.output[1].substring.map(String.init) ?? ""
        let g3 = match.output[3].substring.map(String.init) ?? ""
        return g1 + g3
      }
    }
    file.write(fileContents)
    return violatingRanges.count
  }
}
