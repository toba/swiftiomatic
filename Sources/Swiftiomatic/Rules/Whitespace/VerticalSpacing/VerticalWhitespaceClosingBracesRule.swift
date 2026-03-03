import Foundation

struct VerticalWhitespaceClosingBracesRule: Rule {
    static let id = "vertical_whitespace_closing_braces"
    static let name = "Vertical Whitespace before Closing Braces"
    static let summary = "Don't include vertical whitespace (empty line) before closing braces"
    static let isCorrectable = true
    static let isOptIn = true
    var options = VerticalWhitespaceClosingBracesOptions()

    private let pattern = "((?:\\n[ \\t]*)+)(\\n[ \\t]*[)}\\]])"
    private let trivialLinePattern = "((?:\\n[ \\t]*)+)(\\n[ \\t)}\\]]*$)"

    func validate(file: SwiftSource) -> [RuleViolation] {
        let pattern = options.onlyEnforceBeforeTrivialLines ? trivialLinePattern : pattern

        let patternRegex = regex(pattern)

        return file.violatingRanges(for: pattern).map { violationRange in
            let matchResult = patternRegex.firstMatch(
                in: file.contents, range: violationRange,
            )!
            let group1Sub = matchResult.output[1].substring!
            let violationIndex = file.contents.index(after: group1Sub.startIndex)

            return RuleViolation(
                ruleType: Self.self,
                severity: options.severityConfiguration.severity,
                location: Location(file: file, stringIndex: violationIndex),
            )
        }
    }

    func correct(file: SwiftSource) -> Int {
        let pattern = options.onlyEnforceBeforeTrivialLines ? trivialLinePattern : pattern
        let violatingRanges = file.ruleEnabled(
            violatingRanges: file.violatingRanges(for: pattern), for: self,
        )
        guard violatingRanges.isNotEmpty else {
            return 0
        }
        let patternRegex = regex(pattern)
        var fileContents = file.contents
        for violationRange in violatingRanges.reversed() {
            fileContents = patternRegex
                .replacing(in: fileContents, range: violationRange) { match in
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
