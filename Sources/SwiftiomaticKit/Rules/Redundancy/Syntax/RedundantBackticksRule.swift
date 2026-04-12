import SwiftiomaticSyntax

struct RedundantBackticksRule {
  static let id = "redundant_backticks"
  static let name = "Redundant Backticks"
  static let summary =
    "Backtick-escaped identifiers that are not keywords in their context are redundant"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let foo = bar"),
      Example("func `test something`() {}"),
      Example("let `class` = foo"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let ↓`foo` = bar"),
      Example("func ↓`myFunc`() {}"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("let ↓`foo` = bar"): Example("let foo = bar")
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension RedundantBackticksRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantBackticksRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      guard node.hasRedundantBackticks else { return }
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visitAny(_ node: Syntax) -> Syntax? {
      if let result = super.visitAny(node) { return result }
      guard let token = node.as(TokenSyntax.self),
        let bareName = token.redundantBackticksBareName
      else {
        return nil
      }
      numberOfCorrections += 1
      return Syntax(token.with(\.tokenKind, .identifier(bareName)))
    }
  }
}

extension TokenSyntax {
  /// The bare identifier name if this token has redundant backticks, nil otherwise.
  fileprivate var redundantBackticksBareName: String? {
    guard let bareName = backtickStrippedName,
      bareName.isValidBareIdentifier,
      !bareName.isSwiftKeyword
    else {
      return nil
    }
    return bareName
  }

  fileprivate var hasRedundantBackticks: Bool {
    redundantBackticksBareName != nil
  }

  /// If this token is a backtick-escaped identifier, returns the name without backticks.
  private var backtickStrippedName: String? {
    guard case .identifier(let name) = tokenKind,
      name.hasPrefix("`"), name.hasSuffix("`")
    else {
      return nil
    }
    return String(name.dropFirst().dropLast())
  }
}

extension String {
  /// Whether this string is a valid Swift identifier without backtick escaping.
  fileprivate var isValidBareIdentifier: Bool {
    guard let first = unicodeScalars.first,
      first == "_" || first.properties.isXIDStart
    else {
      return false
    }
    return unicodeScalars.dropFirst().allSatisfy(\.properties.isXIDContinue)
  }
}
