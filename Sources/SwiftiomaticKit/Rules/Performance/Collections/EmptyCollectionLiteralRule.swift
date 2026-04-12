import SwiftiomaticSyntax

struct EmptyCollectionLiteralRule {
  static let id = "empty_collection_literal"
  static let name = "Empty Collection Literal"
  static let summary =
    "Prefer checking `isEmpty` over comparing collection to an empty array or dictionary literal"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("myArray = []"),
      Example("myArray.isEmpty"),
      Example("!myArray.isEmpty"),
      Example("myDict = [:]"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("myArray↓ == []"),
      Example("myArray↓ != []"),
      Example("myArray↓ == [ ]"),
      Example("myDict↓ == [:]"),
      Example("myDict↓ != [:]"),
      Example("myDict↓ == [: ]"),
      Example("myDict↓ == [ :]"),
      Example("myDict↓ == [ : ]"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension EmptyCollectionLiteralRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

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
