import SwiftiomaticSyntax

struct ForceCastRule {
  static let id = "force_cast"
  static let name = "Force Cast"
  static let summary = "Force casts should be avoided"
  static var nonTriggeringExamples: [Example] {
    [
      Example("NSNumber() as? Int")
    ]
  }

  static var triggeringExamples: [Example] {
    [Example("NSNumber() ↓as! Int")]
  }

  var options = SeverityOption<Self>(.error)
}

extension ForceCastRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ForceCastRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AsExprSyntax) {
      if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
        violations.append(node.asKeyword.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: UnresolvedAsExprSyntax) {
      if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
        violations.append(node.asKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
