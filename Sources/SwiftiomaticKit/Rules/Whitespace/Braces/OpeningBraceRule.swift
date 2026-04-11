import Foundation
import SwiftSyntax

struct OpeningBraceRule {
  static let id = "opening_brace"
  static let name = "Opening Brace Spacing"
  static let summary = "Opening braces should be preceded by a single space and on the same line as the declaration"
  static let isCorrectable = true
  var options = OpeningBraceOptions()
}

extension OpeningBraceRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension OpeningBraceRule {
  fileprivate final class Visitor: CodeBlockVisitor<OptionsType> {
    // MARK: - Type Declarations

    override func visitPost(_ node: ActorDeclSyntax) {
      if configuration.ignoreMultilineTypeHeaders,
        hasMultilinePredecessors(node.memberBlock, keyword: node.actorKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      if configuration.ignoreMultilineTypeHeaders,
        hasMultilinePredecessors(node.memberBlock, keyword: node.classKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      if configuration.ignoreMultilineTypeHeaders,
        hasMultilinePredecessors(node.memberBlock, keyword: node.enumKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
      if configuration.ignoreMultilineTypeHeaders,
        hasMultilinePredecessors(node.memberBlock, keyword: node.extensionKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      if configuration.ignoreMultilineTypeHeaders,
        hasMultilinePredecessors(node.memberBlock, keyword: node.protocolKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      if configuration.ignoreMultilineTypeHeaders,
        hasMultilinePredecessors(node.memberBlock, keyword: node.structKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    // MARK: - Conditional Statements

    override func visitPost(_ node: ForStmtSyntax) {
      if configuration.ignoreMultilineStatementConditions,
        hasMultilinePredecessors(node.body, keyword: node.forKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    override func visitPost(_ node: IfExprSyntax) {
      if configuration.ignoreMultilineStatementConditions,
        hasMultilinePredecessors(node.body, keyword: node.ifKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    override func visitPost(_ node: WhileStmtSyntax) {
      if configuration.ignoreMultilineStatementConditions,
        hasMultilinePredecessors(node.body, keyword: node.whileKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    // MARK: - Functions and Initializers

    override func visitPost(_ node: FunctionDeclSyntax) {
      if let body = node.body,
        configuration.shouldIgnoreMultilineFunctionSignatures,
        hasMultilinePredecessors(body, keyword: node.funcKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
      if let body = node.body,
        configuration.shouldIgnoreMultilineFunctionSignatures,
        hasMultilinePredecessors(body, keyword: node.initKeyword)
      {
        return
      }

      super.visitPost(node)
    }

    // MARK: - Other Methods

    /// Checks if a `BracedSyntax` has a multiline predecessor.
    /// For type declarations, the predecessor is the header. For conditional statements,
    /// it is the condition list, and for functions, it is the signature.
    private func hasMultilinePredecessors(
      _ body: some BracedSyntax,
      keyword: TokenSyntax,
    ) -> Bool {
      guard let endToken = body.previousToken(viewMode: .sourceAccurate) else {
        return false
      }
      let startLocation = keyword.endLocation(converter: locationConverter)
      let endLocation = endToken.endLocation(converter: locationConverter)
      let braceLocation = body.leftBrace.endLocation(converter: locationConverter)
      return startLocation.line != endLocation.line && endLocation.line != braceLocation.line
    }

    override func collectViolations(for bracedItem: (some BracedSyntax)?) {
      if let bracedItem, let correction = violationCorrection(bracedItem) {
        violations.append(
          SyntaxViolation(
            position: bracedItem.openingPosition,
            reason: """
              Opening braces should be preceded by a single space and on the same line \
              as the declaration
              """,
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
      if previousLocation.line != leftBraceLocation.line {
        let trailingCommentText = previousToken.trailingTrivia.description
          .trimmingCharacters(
            in: .whitespaces,
          )
        return .init(
          start: previousToken.endPositionBeforeTrailingTrivia,
          end: openingPosition.advanced(by: trailingCommentText.isNotEmpty ? 1 : 0),
          replacement: trailingCommentText.isNotEmpty ? " { \(trailingCommentText)" : " ",
        )
      }
      if previousLocation.column + 1 == leftBraceLocation.column {
        return nil
      }
      if triviaBetween.containsComments {
        if triviaBetween.pieces.last == .spaces(1) {
          return nil
        }
        let comment = triviaBetween.description.trimmingTrailingCharacters(in: .whitespaces)
        return .init(
          start: previousToken
            .endPositionBeforeTrailingTrivia + SourceLength(of: comment),
          end: openingPosition,
          replacement: " ",
        )
      }
      return .init(
        start: previousToken.endPositionBeforeTrailingTrivia,
        end: openingPosition,
        replacement: " ",
      )
    }
  }
}

extension BracedSyntax {
  fileprivate var openingPosition: AbsolutePosition {
    leftBrace.positionAfterSkippingLeadingTrivia
  }
}
