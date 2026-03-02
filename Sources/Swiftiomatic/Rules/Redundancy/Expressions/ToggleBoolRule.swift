import SwiftSyntax
import SwiftSyntaxBuilder

struct ToggleBoolRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ToggleBoolConfiguration()
}

extension ToggleBoolRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ToggleBoolRule {}

extension ToggleBoolRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ExprListSyntax) {
      if node.hasToggleBoolViolation {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ExprListSyntax) -> ExprListSyntax {
      guard node.hasToggleBoolViolation, let firstExpr = node.first,
        let index = node.index(of: firstExpr)
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let elements =
        node
        .with(
          \.[index],
          "\(firstExpr.trimmed).toggle()",
        )
        .dropLast(2)
      let newNode = ExprListSyntax(elements)
        .with(\.leadingTrivia, node.leadingTrivia)
        .with(\.trailingTrivia, node.trailingTrivia)
      return super.visit(newNode)
    }
  }
}

extension ExprListSyntax {
  fileprivate var hasToggleBoolViolation: Bool {
    guard
      count == 3,
      dropFirst().first?.is(AssignmentExprSyntax.self) == true,
      last?.is(PrefixOperatorExprSyntax.self) == true,
      let lhs = first?.trimmedDescription,
      let rhs = last?.trimmedDescription,
      rhs == "!\(lhs)"
    else {
      return false
    }

    return true
  }
}
