import SwiftSyntax

struct NoFallthroughOnlyRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = NoFallthroughOnlyConfiguration()
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
