import Foundation
import SwiftSyntax

struct InitCoderUnavailableRule {
  static let id = "init_coder_unavailable"
  static let name = "Init Coder Unavailable"
  static let summary =
    "Add `@available(*, unavailable)` to `required init(coder:)` when it has no real implementation"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        class Foo: UIView {
          @available(*, unavailable)
          required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      ),
      Example(
        """
        class Foo: UIView {
          required init?(coder: NSCoder) {
            super.init(coder: coder)
          }
        }
        """,
      ),
      Example(
        """
        class Foo: UIView {
          required init?(coder: NSCoder) {
            self.name = ""
            super.init(coder: coder)
          }
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        class Foo: UIView {
          ↓required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
          }
        }
        """,
      ),
      Example(
        """
        class Foo: UIView {
          ↓required init?(coder: NSCoder) {
          }
        }
        """,
      ),
      Example(
        """
        class Foo: UIView {
          ↓required init?(coder aDecoder: NSCoder) {
            fatalError()
          }
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension InitCoderUnavailableRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension InitCoderUnavailableRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InitializerDeclSyntax) {
      // Must be `required init`
      guard node.modifiers.contains(keyword: .required) else { return }

      // Must have `coder` as first parameter label
      guard let firstParam = node.signature.parameterClause.parameters.first,
        firstParam.firstName.text == "coder"
      else {
        return
      }

      // Must not already have @available(*, unavailable)
      guard
        !node.attributes.contains(where: { attr in
          guard let attrSyntax = attr.as(AttributeSyntax.self),
            attrSyntax.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "available"
          else {
            return false
          }
          return attrSyntax.description.contains("unavailable")
        })
      else {
        return
      }

      // Body must be empty or contain only fatalError
      guard let body = node.body else { return }
      guard isEmptyOrFatalError(body) else { return }

      // Report at the `required` keyword position
      violations.append(node.modifiers.first!.positionAfterSkippingLeadingTrivia)
    }

    private func isEmptyOrFatalError(_ body: CodeBlockSyntax) -> Bool {
      let stmts = body.statements
      if stmts.isEmpty { return true }
      if stmts.count != 1 { return false }

      let item = stmts.first!.item
      // Try as FunctionCallExprSyntax directly (Swift 6 parses top-level calls this way)
      if let call = item.as(FunctionCallExprSyntax.self),
        call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "fatalError"
      {
        return true
      }
      // Try wrapped in ExpressionStmtSyntax
      if let exprStmt = item.as(ExpressionStmtSyntax.self),
        let call = exprStmt.expression.as(FunctionCallExprSyntax.self),
        call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "fatalError"
      {
        return true
      }
      return false
    }
  }
}
