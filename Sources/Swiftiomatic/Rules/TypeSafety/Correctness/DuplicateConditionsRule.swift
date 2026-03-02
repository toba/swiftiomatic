import SwiftSyntax

struct DuplicateConditionsRule {
  var options = SeverityConfiguration<Self>(.error)

  static let configuration = DuplicateConditionsConfiguration()
}

extension DuplicateConditionsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DuplicateConditionsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: IfExprSyntax) {
      if node.parent?.is(IfExprSyntax.self) == true {
        // We can skip these cases - they will be picked up when we visit the top level `if`
        return
      }

      var maybeCurr: IfExprSyntax? = node
      var statementChain: [IfExprSyntax] = []
      while let curr = maybeCurr {
        statementChain.append(curr)
        maybeCurr = curr.elseBody?.as(IfExprSyntax.self)
      }

      let positionsByConditions =
        statementChain
        .reduce(into: [Set<String>: [AbsolutePosition]]()) { acc, elt in
          let conditions = elt.conditions.map(\.condition.trimmedDescription)
          let location = elt.conditions.positionAfterSkippingLeadingTrivia
          acc[Set(conditions), default: []].append(location)
        }

      addViolations(Array(positionsByConditions.values))
    }

    override func visitPost(_ node: SwitchCaseListSyntax) {
      let switchCases = node.compactMap { $0.as(SwitchCaseSyntax.self) }

      let positionsByCondition =
        switchCases
        .reduce(into: [String: [AbsolutePosition]]()) { acc, elt in
          // Defaults don't have a condition to worry about
          guard case .case(let caseLabel) = elt.label else { return }
          for caseItem in caseLabel.caseItems {
            let pattern = caseItem
              .pattern
              .trimmedDescription
            let whereClause =
              caseItem
              .whereClause?
              .trimmedDescription
              ?? ""
            let location = caseItem.positionAfterSkippingLeadingTrivia
            acc[pattern + whereClause, default: []].append(location)
          }
        }

      addViolations(Array(positionsByCondition.values))
    }

    private func addViolations(_ positionsByCondition: [[AbsolutePosition]]) {
      let duplicatedPositions =
        positionsByCondition
        .filter { $0.count > 1 }
        .flatMap(\.self)

      violations.append(contentsOf: duplicatedPositions)
    }
  }
}
