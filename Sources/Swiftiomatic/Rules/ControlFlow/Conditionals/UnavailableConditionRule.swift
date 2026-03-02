import SwiftSyntax

struct UnavailableConditionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UnavailableConditionConfiguration()
}

extension UnavailableConditionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnavailableConditionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: IfExprSyntax) {
      guard node.body.statements.isEmpty else {
        return
      }

      guard let condition = node.conditions.onlyElement,
        let availability = asAvailabilityCondition(condition.condition)
      else {
        return
      }

      if otherAvailabilityCheckInvolved(ifStmt: node) {
        // If there are other conditional branches with availability checks it might not be possible
        // to just invert the first one.
        return
      }

      violations.append(
        SyntaxViolation(
          position: availability.positionAfterSkippingLeadingTrivia,
          reason: reason(for: availability),
        ),
      )
    }

    private func asAvailabilityCondition(_ condition: ConditionElementSyntax.Condition)
      -> AvailabilityConditionSyntax?
    {
      condition.as(AvailabilityConditionSyntax.self)
    }

    private func otherAvailabilityCheckInvolved(ifStmt: IfExprSyntax) -> Bool {
      if let elseBody = ifStmt.elseBody,
        let nestedIfStatement = elseBody.as(IfExprSyntax.self)
      {
        if nestedIfStatement.conditions.map(\.condition).compactMap(asAvailabilityCondition)
          .isNotEmpty
        {
          return true
        }
        return otherAvailabilityCheckInvolved(ifStmt: nestedIfStatement)
      }
      return false
    }

    private func reason(for condition: AvailabilityConditionSyntax) -> String {
      switch condition.availabilityKeyword.tokenKind {
      case .poundAvailable:
        return "Use #unavailable instead of #available with an empty body"
      case .poundUnavailable:
        return "Use #available instead of #unavailable with an empty body"
      default:
        Console.fatalError("Unknown availability check type.")
      }
    }
  }
}
