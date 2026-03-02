import SwiftSyntax

struct ClosureBodyLengthRule {
  private static let defaultWarningThreshold = 30

  var options = SeverityLevelsConfiguration<Self>(
    warning: Self.defaultWarningThreshold, error: 100,
  )

  static let configuration = ClosureBodyLengthConfiguration()
}

extension ClosureBodyLengthRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ClosureBodyLengthRule {}

extension ClosureBodyLengthRule {
  fileprivate final class Visitor: BodyLengthVisitor<OptionsType> {
    override func visitPost(_ node: ClosureExprSyntax) {
      registerViolations(
        leftBrace: node.leftBrace,
        rightBrace: node.rightBrace,
        violationNode: node.leftBrace,
        objectName: "Closure",
      )
    }
  }
}
