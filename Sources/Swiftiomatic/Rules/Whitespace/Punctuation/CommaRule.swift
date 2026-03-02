import Foundation
import SwiftSyntax

struct CommaRule: CorrectableRule, SyntaxOnlyRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = CommaConfiguration()

  func validate(file: SwiftSource) -> [RuleViolation] {
    violationRanges(in: file).map {
      RuleViolation(
        ruleDescription: Self.description,
        severity: options.severity,
        location: Location(file: file, byteOffset: $0.0.location),
      )
    }
  }

  private func violationRanges(in file: SwiftSource) -> [(ByteRange, shouldAddSpace: Bool)] {
    let syntaxTree = file.syntaxTree

    return
      syntaxTree
      .windowsOfThreeTokens()
      .compactMap { previous, current, next -> (ByteRange, shouldAddSpace: Bool)? in
        if current.tokenKind != .comma {
          return nil
        }
        if !previous.trailingTrivia.isEmpty,
          !previous.trailingTrivia.containsBlockComments()
        {
          let start = ByteCount(previous.endPositionBeforeTrailingTrivia)
          let end = ByteCount(current.endPosition)
          let nextIsNewline = next.leadingTrivia.containsNewlines()
          return (
            ByteRange(location: start, length: end - start),
            shouldAddSpace: !nextIsNewline,
          )
        }
        if !current.trailingTrivia.starts(with: [.spaces(1)]),
          !next.leadingTrivia.containsNewlines()
        {
          let start = ByteCount(current.position)
          let end = ByteCount(next.positionAfterSkippingLeadingTrivia)
          return (
            ByteRange(location: start, length: end - start),
            shouldAddSpace: true,
          )
        }
        return nil
      }
  }

  func correct(file: SwiftSource) -> Int {
    let initialRanges = Dictionary(
      uniqueKeysWithValues: violationRanges(in: file)
        .compactMap { byteRange, shouldAddSpace in
          file.stringView
            .byteRangeToStringRange(byteRange)
            .flatMap { ($0, shouldAddSpace) }
        },
    )

    let violatingRanges = file.ruleEnabled(
      violatingRanges: Array(initialRanges.keys),
      for: self,
    )
    guard violatingRanges.isNotEmpty else {
      return 0
    }

    var contents = file.contents
    for range in violatingRanges.sorted(by: { $0.lowerBound > $1.lowerBound }) {
      let shouldAddSpace = initialRanges[range] ?? true
      contents.replaceSubrange(range, with: ",\(shouldAddSpace ? " " : "")")
    }
    file.write(contents)
    return violatingRanges.count
  }
}

extension Trivia {
  fileprivate func containsBlockComments() -> Bool {
    contains { piece in
      if case .blockComment = piece {
        return true
      }
      return false
    }
  }
}
