import SwiftSyntax

/// this rule exists due to a compiler bug: https://github.com/apple/swift/issues/51036
struct NSNumberInitAsFunctionReferenceRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = NSNumberInitAsFunctionReferenceConfiguration()
}

extension NSNumberInitAsFunctionReferenceRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NSNumberInitAsFunctionReferenceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      guard node.declName.argumentNames.isEmptyOrNil,
        node.declName.baseName.text == "init",
        node.parent?.as(FunctionCallExprSyntax.self) == nil,
        let baseText = node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text,
        baseText == "NSNumber" || baseText == "NSDecimalNumber"
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension DeclNameArgumentsSyntax? {
  fileprivate var isEmptyOrNil: Bool {
    self?.arguments.isEmpty ?? true
  }
}
