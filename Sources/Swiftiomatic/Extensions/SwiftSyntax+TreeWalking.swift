import SwiftSyntax

// Workaround for SR-10121: allows using `Self` in a closure on SyntaxVisitor subclasses
protocol TreeWalking: SyntaxVisitor {}
extension SyntaxVisitor: TreeWalking {}

extension TreeWalking {
  func walk<T>(tree: some SyntaxProtocol, handler: (Self) -> T) -> T {
    walk(tree)
    return handler(self)
  }

  func walk<T>(file: SwiftSource, handler: (Self) -> [T]) -> [T] {
    walk(tree: file.syntaxTree, handler: handler)
  }
}

extension SyntaxProtocol {
  func windowsOfThreeTokens() -> [(TokenSyntax, TokenSyntax, TokenSyntax)] {
    Array(tokens(viewMode: .sourceAccurate))
      .windows(ofCount: 3)
      .map { tokens in
        let previous = tokens[tokens.startIndex]
        let current = tokens[tokens.startIndex + 1]
        let next = tokens[tokens.startIndex + 2]
        return (previous, current, next)
      }
  }

  func isContainedIn(regions: [SourceRange], locationConverter: SourceLocationConverter) -> Bool {
    positionAfterSkippingLeadingTrivia.isContainedIn(
      regions: regions, locationConverter: locationConverter,
    )
  }
}

extension AbsolutePosition {
  func isContainedIn(regions: [SourceRange], locationConverter: SourceLocationConverter) -> Bool {
    regions.contains { region in
      region.contains(self, locationConverter: locationConverter)
    }
  }
}

extension Range<AbsolutePosition> {
  func toSourceKitByteRange() -> ByteRange {
    ByteRange(
      location: ByteCount(lowerBound),
      length: ByteCount(upperBound.utf8Offset) - ByteCount(lowerBound.utf8Offset),
    )
  }
}

extension TokenKind {
  var isEqualityComparison: Bool {
    self == .binaryOperator("==") || self == .binaryOperator("!=")
  }

  var isUnavailableKeyword: Bool {
    self == .keyword(.unavailable) || self == .identifier("unavailable")
  }
}
