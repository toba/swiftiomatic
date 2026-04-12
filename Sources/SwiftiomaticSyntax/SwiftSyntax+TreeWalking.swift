package import SwiftSyntax

/// Workaround for SR-10121 that allows using `Self` in a closure on ``SyntaxVisitor`` subclasses
package protocol TreeWalking: SyntaxVisitor {}
extension SyntaxVisitor: TreeWalking {}

extension TreeWalking {
  /// Walk the syntax tree and extract a result from the visitor's state
  ///
  /// - Parameters:
  ///   - tree: The syntax node to walk.
  ///   - handler: A closure that reads accumulated state from the visitor after the walk.
  package func walk<T>(tree: some SyntaxProtocol, handler: (Self) -> T) -> T {
    walk(tree)
    return handler(self)
  }

  /// Walk a ``SwiftSource`` file and collect results from the visitor's state
  ///
  /// - Parameters:
  ///   - file: The Swift source file to walk.
  ///   - handler: A closure that reads accumulated state from the visitor after the walk.
  package func walk<T>(file: SwiftSource, handler: (Self) -> [T]) -> [T] {
    walk(tree: file.syntaxTree, handler: handler)
  }
}

extension SyntaxProtocol {
  /// Walk up the parent chain and return the first ancestor matching the given type
  ///
  /// - Parameters:
  ///   - _: The ``SyntaxProtocol`` type to search for.
  package func nearestAncestor<T: SyntaxProtocol>(ofType _: T.Type) -> T? {
    var current: Syntax? = parent
    while let node = current {
      if let typed = node.as(T.self) { return typed }
      current = node.parent
    }
    return nil
  }

  /// Sliding windows of three consecutive tokens in source-accurate order
  package func windowsOfThreeTokens() -> [(TokenSyntax, TokenSyntax, TokenSyntax)] {
    Array(tokens(viewMode: .sourceAccurate))
      .windows(ofCount: 3)
      .map { tokens in
        let previous = tokens[tokens.startIndex]
        let current = tokens[tokens.startIndex + 1]
        let next = tokens[tokens.startIndex + 2]
        return (previous, current, next)
      }
  }

  /// Whether this node's position falls within any of the given source regions
  ///
  /// - Parameters:
  ///   - regions: Source ranges to test against.
  ///   - locationConverter: Converter for mapping absolute positions to source locations.
  package func isContainedIn(regions: [SourceRange], locationConverter: SourceLocationConverter) -> Bool {
    positionAfterSkippingLeadingTrivia.isContainedIn(
      regions: regions, locationConverter: locationConverter,
    )
  }
}

extension AbsolutePosition {
  /// Whether this absolute position falls within any of the given source regions
  ///
  /// - Parameters:
  ///   - regions: Source ranges to test against.
  ///   - locationConverter: Converter for mapping absolute positions to source locations.
  package func isContainedIn(regions: [SourceRange], locationConverter: SourceLocationConverter) -> Bool {
    regions.contains { (region: SourceRange) in
      region.contains(self, locationConverter: locationConverter)
    }
  }
}

extension Range<AbsolutePosition> {
  /// Convert this absolute-position range to a ``ByteRange`` for SourceKit requests
  package func toSourceKitByteRange() -> ByteRange {
    ByteRange(
      location: ByteCount(lowerBound),
      length: ByteCount(upperBound.utf8Offset) - ByteCount(lowerBound.utf8Offset),
    )
  }
}

extension TokenKind {
  package var isEqualityComparison: Bool {
    self == .binaryOperator("==") || self == .binaryOperator("!=")
  }

  package var isUnavailableKeyword: Bool {
    self == .keyword(.unavailable) || self == .identifier("unavailable")
  }
}
