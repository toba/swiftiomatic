import SwiftSyntax

/// Collects line numbers that fall within multiline string literals (`"""`)
///
/// Rules that need to skip or treat multiline string content differently can
/// use the resulting ``linesSpanned`` set to filter those lines out.
final class MultilineStringLiteralVisitor: SyntaxVisitor {
  private let locationConverter: SourceLocationConverter

  /// Line numbers covered by at least one multiline string literal
  private(set) var linesSpanned = Set<Int>()

  /// Creates a visitor with the given location converter
  ///
  /// - Parameters:
  ///   - locationConverter: The converter for mapping positions to line numbers.
  init(locationConverter: SourceLocationConverter) {
    self.locationConverter = locationConverter
    super.init(viewMode: .sourceAccurate)
  }

  override func visitPost(_ node: StringLiteralExprSyntax) {
    guard node.openingQuote.tokenKind == .multilineStringQuote else {
      return
    }
    let startLocation = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
    let endLocation = locationConverter.location(for: node.endPositionBeforeTrailingTrivia)
    guard startLocation.line < endLocation.line else {
      return
    }
    linesSpanned.formUnion(startLocation.line...endLocation.line)
  }
}
