import SwiftSyntax
import SwiftSyntaxBuilder

struct ToggleBoolRule {
  static let id = "toggle_bool"
  static let name = "Toggle Bool"
  static let summary = "Prefer `someBool.toggle()` over `someBool = !someBool`"
  static let isCorrectable = true
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("isHidden.toggle()"),
      Example("view.clipsToBounds.toggle()"),
      Example("func foo() { abc.toggle() }"),
      Example("view.clipsToBounds = !clipsToBounds"),
      Example("disconnected = !connected"),
      Example("result = !result.toggle()"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓isHidden = !isHidden"),
      Example("↓view.clipsToBounds = !view.clipsToBounds"),
      Example("func foo() { ↓abc = !abc }"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("↓isHidden = !isHidden"): Example("isHidden.toggle()"),
      Example("↓view.clipsToBounds = !view.clipsToBounds"): Example(
        "view.clipsToBounds.toggle()",
      ),
      Example("func foo() { ↓abc = !abc }"): Example("func foo() { abc.toggle() }"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension ToggleBoolRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

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
