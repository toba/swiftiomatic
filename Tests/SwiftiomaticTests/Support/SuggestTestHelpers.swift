import Foundation
import Testing

@testable import SwiftiomaticKit

/// Load a fixture file relative to the caller and validate with a rule.
func suggestViolations(
  _ rule: some Rule,
  fixture: String,
  caller: String = #filePath,
) throws -> [RuleViolation] {
  let path = URL(filePath: caller)
    .deletingLastPathComponent()
    .appendingPathComponent("SuggestFixtures/\(fixture).swift")
    .path
  let file = try #require(SwiftSource(path: path))
  return rule.validate(file: file)
}

/// Overload for CollectingRule (e.g. CaseIterableUsageRule).
func suggestViolations<R: CollectingRule>(
  _ rule: R,
  fixture: String,
  caller: String = #filePath,
) throws -> [RuleViolation] {
  let path = URL(filePath: caller)
    .deletingLastPathComponent()
    .appendingPathComponent("SuggestFixtures/\(fixture).swift")
    .path
  let file = try #require(SwiftSource(path: path))
  let info = rule.collectInfo(for: file)
  return rule.validate(file: file, collectedInfo: [file: info])
}

/// Filter violations containing `text` in their reason, then assert count.
func expectFindings(
  _ violations: [RuleViolation],
  containing text: String,
  atLeast count: Int = 1,
  sourceLocation: SourceLocation = #_sourceLocation,
) {
  let matches = violations.filter { $0.reason.contains(text) }
  #expect(
    matches.count >= count,
    "Expected >= \(count) findings containing '\(text)', got \(matches.count)",
    sourceLocation: sourceLocation,
  )
}
