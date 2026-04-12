import Foundation
import SwiftiomaticSyntax

struct ContrastedOpeningBraceRule {
  static let id = "contrasted_opening_brace"
  static let name = "Contrasted Opening Brace"
  static let summary = "Opening braces should be on a separate line from the preceding declaration"
  static let isCorrectable = true
  static let isOptIn = true
  var options = SeverityOption<Self>(.warning)
}

extension ContrastedOpeningBraceRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ContrastedOpeningBraceRule {
  fileprivate final class Visitor: CodeBlockVisitor<OptionsType> {
    override func collectViolations(for bracedItem: (some BracedSyntax)?) {
      if let bracedItem, let correction = violationCorrection(bracedItem) {
        violations.append(
          SyntaxViolation(
            position: bracedItem.openingPosition,
            reason: "Opening brace should be on a separate line",
            correction: correction,
          ),
        )
      }
    }

    private func violationCorrection(_ node: some BracedSyntax) -> SyntaxViolation
      .Correction?
    {
      let leftBrace = node.leftBrace
      guard let previousToken = leftBrace.previousToken(viewMode: .sourceAccurate) else {
        return nil
      }
      let openingPosition = node.openingPosition
      let triviaBetween = previousToken.trailingTrivia + leftBrace.leadingTrivia
      let previousLocation = previousToken.endLocation(converter: locationConverter)
      let leftBraceLocation = leftBrace.startLocation(converter: locationConverter)
      let parentStartColumn =
        node
        .indentationDecidingParent?
        .startLocation(converter: locationConverter)
        .column ?? 1
      if previousLocation.line + 1 == leftBraceLocation.line,
        leftBraceLocation.column == parentStartColumn
      {
        return nil
      }
      let comment = triviaBetween.description.trimmingTrailingCharacters(
        in: .whitespacesAndNewlines,
      )
      return .init(
        start: previousToken.endPositionBeforeTrailingTrivia + SourceLength(of: comment),
        end: openingPosition,
        replacement: "\n" + String(repeating: " ", count: parentStartColumn - 1),
      )
    }
  }
}

extension BracedSyntax {
  fileprivate var openingPosition: AbsolutePosition {
    leftBrace.positionAfterSkippingLeadingTrivia
  }

  fileprivate var indentationDecidingParent: (any SyntaxProtocol)? {
    if let catchClause = parent?.as(CatchClauseSyntax.self) {
      return catchClause.parent?.as(CatchClauseListSyntax.self)?.parent?.as(DoStmtSyntax.self)
    }
    if let ifExpr = parent?.as(IfExprSyntax.self) {
      return ifExpr.indentationDecidingParent
    }
    if let binding = parent?.as(PatternBindingSyntax.self) {
      return binding.parent?.as(PatternBindingListSyntax.self)?.parent?
        .as(VariableDeclSyntax.self)
    }
    if let closure = `as`(ClosureExprSyntax.self),
      closure.keyPathInParent == \FunctionCallExprSyntax.trailingClosure
    {
      return closure.leftBrace.previousIndentationDecidingToken
    }
    if let closureLabel = parent?.as(MultipleTrailingClosureElementSyntax.self)?.label {
      return closureLabel.previousIndentationDecidingToken
    }
    return parent
  }
}

extension TokenSyntax {
  fileprivate var previousIndentationDecidingToken: TokenSyntax {
    var indentationDecidingToken = self
    repeat {
      if let previousToken =
        indentationDecidingToken
        .previousToken(viewMode: .sourceAccurate)
      {
        indentationDecidingToken = previousToken
      } else {
        break
      }
    } while !indentationDecidingToken.leadingTrivia.containsNewlines()
    return indentationDecidingToken
  }
}

extension IfExprSyntax {
  fileprivate var indentationDecidingParent: any SyntaxProtocol {
    if keyPathInParent == \IfExprSyntax.elseBody, let parent = parent?.as(IfExprSyntax.self) {
      return parent.indentationDecidingParent
    }
    return self
  }
}
