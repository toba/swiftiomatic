import SwiftSyntax

struct NoFallthroughOnlyRule {
    static let id = "no_fallthrough_only"
    static let name = "No Fallthrough only"
    static let summary = "Fallthroughs can only be used if the `case` contains at least one other statement"
  var options = SeverityOption<Self>(.warning)

}

extension NoFallthroughOnlyRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NoFallthroughOnlyRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchCaseListSyntax) {
      let cases = node.compactMap { $0.as(SwitchCaseSyntax.self) }

      let localViolations = cases.enumerated()
        .compactMap { index, element -> AbsolutePosition? in
          if let fallthroughStmt = element.statements.onlyElement?.item.as(
            FallThroughStmtSyntax.self,
          ) {
            if case let nextCaseIndex = cases.index(after: index),
              nextCaseIndex < cases.endIndex,
              case let nextCase = cases[nextCaseIndex],
              nextCase.attribute != nil
            {
              return nil
            }
            return fallthroughStmt.positionAfterSkippingLeadingTrivia
          }
          return nil
        }

      violations.append(contentsOf: localViolations)
    }
  }
}
