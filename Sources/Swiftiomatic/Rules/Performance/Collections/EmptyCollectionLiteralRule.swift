import SwiftSyntax

struct EmptyCollectionLiteralRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = EmptyCollectionLiteralConfiguration()
}

extension EmptyCollectionLiteralRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension EmptyCollectionLiteralRule {}

extension EmptyCollectionLiteralRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      guard
        node.tokenKind.isEqualityComparison,
        let violationPosition = node.previousToken(viewMode: .sourceAccurate)?
          .endPositionBeforeTrailingTrivia,
        let expectedLeftSquareBracketToken = node.nextToken(viewMode: .sourceAccurate),
        expectedLeftSquareBracketToken.tokenKind == .leftSquare,
        let expectedColonToken = expectedLeftSquareBracketToken.nextToken(
          viewMode: .sourceAccurate,
        ),
        expectedColonToken.tokenKind == .colon
          || expectedColonToken
            .tokenKind == .rightSquare
      else {
        return
      }

      violations.append(violationPosition)
    }
  }
}
