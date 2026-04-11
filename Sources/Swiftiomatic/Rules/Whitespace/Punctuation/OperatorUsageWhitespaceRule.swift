import Foundation
import SwiftSyntax

struct OperatorUsageWhitespaceRule: Rule {
  static let id = "operator_usage_whitespace"
  static let name = "Operator Usage Whitespace"
  static let summary =
    "Operators should be surrounded by a single whitespace when they are being used"
  static let isCorrectable = true
  static let isOptIn = true
  var options = OperatorUsageWhitespaceOptions()

  func validate(file: SwiftSource) -> [RuleViolation] {
    violationRanges(file: file).map { range, _ in
      RuleViolation(
        ruleType: Self.self,
        severity: options.severityConfiguration.severity,
        location: Location(file: file, byteOffset: range.location),
      )
    }
  }

  private func violationRanges(file: SwiftSource) -> [(ByteRange, String)] {
    OperatorUsageWhitespaceVisitor(
      allowedNoSpaceOperators: options.allowedNoSpaceOperators,
    )
    .walk(file: file, handler: \.violationRanges)
    .filter { byteRange, _ in
      !options.skipAlignedConstants || !isAlignedConstant(in: byteRange, file: file)
    }.sorted { lhs, rhs in
      lhs.0.location < rhs.0.location
    }
  }

  func correct(file: SwiftSource) -> Int {
    let violatingRanges = violationRanges(file: file)
      .compactMap { byteRange, correction -> (NSRange, String)? in
        guard let range = file.stringView.byteRangeToNSRange(byteRange) else {
          return nil
        }

        return (range, correction)
      }
      .filter { range, _ in
        file.ruleEnabled(violatingRanges: [range], for: self).isNotEmpty
      }

    var correctedContents = file.contents
    var numberOfCorrections = 0
    for (violatingRange, correction) in violatingRanges.reversed() {
      if let indexRange = correctedContents.nsRangeToIndexRange(violatingRange) {
        correctedContents = correctedContents.replacingCharacters(
          in: indexRange,
          with: correction,
        )
        numberOfCorrections += 1
      }
    }
    file.write(correctedContents)
    return numberOfCorrections
  }

  private func isAlignedConstant(in byteRange: ByteRange, file: SwiftSource) -> Bool {
    // Make sure we have match with assignment operator and with spaces before it
    guard let matchedString = file.stringView.substringWithByteRange(byteRange) else {
      return false
    }
    let equalityOperatorRegex = regex("\\s+=\\s")

    guard
      let match = equalityOperatorRegex.firstMatch(
        in: matchedString, range: matchedString.fullNSRange,
      ),
      NSRange(match.range, in: matchedString) == matchedString.fullNSRange
    else {
      return false
    }

    guard
      let (lineNumber, _) = file.stringView
        .lineAndCharacter(forByteOffset: byteRange.upperBound),
      case let lineIndex = lineNumber - 1, lineIndex >= 0
    else {
      return false
    }

    // Find lines above and below with the same location of =
    let currentLine = file.stringView.lines[lineIndex].content
    let index = currentLine.firstIndex(of: "=")
    guard let offset = index.map({ currentLine.distance(from: currentLine.startIndex, to: $0) })
    else {
      return false
    }

    // Look around for assignment operator in lines around
    let lineIndexesAround = (1...options.linesLookAround)
      .flatMap { [lineIndex + $0, lineIndex - $0] }

    func isValidIndex(_ idx: Int) -> Bool {
      idx != lineIndex && idx >= 0 && idx < file.stringView.lines.count
    }

    for lineIndex in lineIndexesAround where isValidIndex(lineIndex) {
      let line = file.stringView.lines[lineIndex].content
      guard !line.isEmpty else { continue }
      let index = line.index(
        line.startIndex,
        offsetBy: offset,
        limitedBy: line.index(line.endIndex, offsetBy: -1),
      )
      if index.map({ line[$0] }) == "=" {
        return true
      }
    }

    return false
  }
}

private final class OperatorUsageWhitespaceVisitor: SyntaxVisitor {
  private let allowedNoSpaceOperators: Set<String>
  private(set) var violationRanges: [(ByteRange, String)] = []

  init(allowedNoSpaceOperators: [String]) {
    self.allowedNoSpaceOperators = Set(allowedNoSpaceOperators)
    super.init(viewMode: .sourceAccurate)
  }

  override func visitPost(_ node: BinaryOperatorExprSyntax) {
    if let violation = violation(operatorToken: node.operator) {
      violationRanges.append(violation)
    }
  }

  override func visitPost(_ node: InitializerClauseSyntax) {
    if let violation = violation(operatorToken: node.equal) {
      violationRanges.append(violation)
    }
  }

  override func visitPost(_ node: TypeInitializerClauseSyntax) {
    if let violation = violation(operatorToken: node.equal) {
      violationRanges.append(violation)
    }
  }

  override func visitPost(_ node: AssignmentExprSyntax) {
    if let violation = violation(operatorToken: node.equal) {
      violationRanges.append(violation)
    }
  }

  override func visitPost(_ node: TernaryExprSyntax) {
    if let violation = violation(operatorToken: node.colon) {
      violationRanges.append(violation)
    }

    if let violation = violation(operatorToken: node.questionMark) {
      violationRanges.append(violation)
    }
  }

  override func visitPost(_ node: UnresolvedTernaryExprSyntax) {
    if let violation = violation(operatorToken: node.colon) {
      violationRanges.append(violation)
    }

    if let violation = violation(operatorToken: node.questionMark) {
      violationRanges.append(violation)
    }
  }

  private func violation(operatorToken: TokenSyntax) -> (ByteRange, String)? {
    guard let previousToken = operatorToken.previousToken(viewMode: .sourceAccurate),
      let nextToken = operatorToken.nextToken(viewMode: .sourceAccurate)
    else {
      return nil
    }

    let noSpacingBefore =
      previousToken.trailingTrivia.isEmpty && operatorToken.leadingTrivia.isEmpty
    let noSpacingAfter = operatorToken.trailingTrivia.isEmpty && nextToken.leadingTrivia.isEmpty
    let noSpacing = noSpacingBefore || noSpacingAfter

    let operatorText = operatorToken.text
    if noSpacing, allowedNoSpaceOperators.contains(operatorText) {
      return nil
    }

    let tooMuchSpacingBefore =
      previousToken.trailingTrivia.containsTooMuchWhitespacing
      && !operatorToken.leadingTrivia.containsNewlines()
    let tooMuchSpacingAfter =
      operatorToken.trailingTrivia.containsTooMuchWhitespacing
      && !operatorToken.trailingTrivia.containsNewlines()

    let tooMuchSpacing =
      (tooMuchSpacingBefore || tooMuchSpacingAfter)
      && !operatorToken.leadingTrivia
        .containsComments
      && !operatorToken.trailingTrivia.containsComments
      && !nextToken.leadingTrivia
        .containsComments

    guard noSpacing || tooMuchSpacing else {
      return nil
    }

    let location = ByteCount(previousToken.endPositionBeforeTrailingTrivia)
    let endPosition = ByteCount(nextToken.positionAfterSkippingLeadingTrivia)
    let range = ByteRange(
      location: location,
      length: endPosition - location,
    )

    let correction =
      allowedNoSpaceOperators.contains(operatorText) ? operatorText : " \(operatorText) "
    return (range, correction)
  }
}

extension Trivia {
  fileprivate var containsTooMuchWhitespacing: Bool {
    contains { element in
      guard case .spaces(let spaces) = element, spaces > 1 else {
        return false
      }

      return true
    }
  }
}
