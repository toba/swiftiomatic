import SwiftiomaticSyntax

struct ForceTryRule {
  static let id = "force_try"
  static let name = "Force Try"
  static let summary = "Force tries should be avoided"
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        func a() throws {}
        do {
          try a()
        } catch {}
        """,
      )
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        func a() throws {}
        ↓try! a()
        """,
      )
    ]
  }

  var options = SeverityOption<Self>(.error)
}

extension ForceTryRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ForceTryRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TryExprSyntax) {
      if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
