import Foundation
import SwiftSyntax

struct ColonRule: SubstitutionCorrectableRule, SyntaxOnlyRule {
    static let id = "colon"
    static let name = "Colon Spacing"
    static let summary = ""
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        ColonRuleExamples.nonTriggeringExamples
    }
    static var triggeringExamples: [Example] {
        ColonRuleExamples.triggeringExamples
    }
    static var corrections: [Example: Example] {
        ColonRuleExamples.corrections
    }
  var options = ColonOptions()

  func validate(file: SwiftSource) -> [RuleViolation] {
    violationRanges(in: file).map { range in
      RuleViolation(
        ruleType: Self.self,
        severity: options.severityConfiguration.severity,
        location: Location(file: file, stringIndex: range.lowerBound),
      )
    }
  }

  func violationRanges(in file: SwiftSource) -> [Range<String.Index>] {
    let syntaxTree = file.syntaxTree
    let visitor = ColonRuleVisitor(viewMode: .sourceAccurate)
    visitor.walk(syntaxTree)
    let positionsToSkip = visitor.positionsToSkip
    let dictionaryPositions = visitor.dictionaryPositions
    let caseStatementPositions = visitor.caseStatementPositions

    return
      syntaxTree
      .windowsOfThreeTokens()
      .compactMap { previous, current, next -> ByteRange? in
        if current.tokenKind != .colon
          || !options.applyToDictionaries
            && dictionaryPositions
              .contains(current.position)
          || positionsToSkip.contains(current.position)
        {
          return nil
        }

        // [:]
        if previous.tokenKind == .leftSquare,
          next.tokenKind == .rightSquare,
          previous.trailingTrivia.isEmpty,
          current.leadingTrivia.isEmpty,
          current.trailingTrivia.isEmpty,
          next.leadingTrivia.isEmpty
        {
          return nil
        }

        if previous.trailingTrivia.isNotEmpty,
          !previous.trailingTrivia.containsBlockComments()
        {
          let start = ByteCount(previous.endPositionBeforeTrailingTrivia)
          let end = ByteCount(current.endPosition)
          return ByteRange(location: start, length: end - start)
        }
        if current.trailingTrivia != [.spaces(1)],
          !next.leadingTrivia.containsNewlines()
        {
          if case .spaces(1) = current.trailingTrivia.first {
            return nil
          }

          let flexibleRightSpacing =
            options.flexibleRightSpacing
            || caseStatementPositions
              .contains(current.position)
          if flexibleRightSpacing, current.trailingTrivia.isNotEmpty {
            return nil
          }

          let length: ByteCount
          if case .spaces(let spaces) = current.trailingTrivia.first {
            length = ByteCount(spaces + 1)
          } else {
            length = 1
          }

          return ByteRange(location: ByteCount(current.position), length: length)
        }
        return nil
      }
      .compactMap { byteRange in
        file.stringView.byteRangeToStringRange(byteRange)
      }
  }

  func substitution(for violationRange: Range<String.Index>, in _: SwiftSource) -> (
    Range<String.Index>, String
  )? {
    (violationRange, ": ")
  }
}

private final class ColonRuleVisitor: SyntaxVisitor {
  var positionsToSkip: [AbsolutePosition] = []
  var dictionaryPositions: [AbsolutePosition] = []
  var caseStatementPositions: [AbsolutePosition] = []

  override func visitPost(_ node: TernaryExprSyntax) {
    positionsToSkip.append(node.colon.position)
  }

  override func visitPost(_ node: DeclNameArgumentsSyntax) {
    positionsToSkip.append(
      contentsOf: node.tokens(viewMode: .sourceAccurate)
        .filter { $0.tokenKind == .colon }
        .map(\.position),
    )
  }

  override func visitPost(_ node: ObjCSelectorPieceSyntax) {
    if let colon = node.colon {
      positionsToSkip.append(colon.position)
    }
  }

  override func visitPost(_ node: OperatorPrecedenceAndTypesSyntax) {
    positionsToSkip.append(node.colon.position)
  }

  override func visitPost(_ node: UnresolvedTernaryExprSyntax) {
    positionsToSkip.append(node.colon.position)
  }

  override func visitPost(_ node: DictionaryElementSyntax) {
    dictionaryPositions.append(node.colon.position)
  }

  override func visitPost(_ node: SwitchCaseLabelSyntax) {
    caseStatementPositions.append(node.colon.position)
  }

  override func visitPost(_ node: SwitchDefaultLabelSyntax) {
    caseStatementPositions.append(node.colon.position)
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
