import SwiftSyntax

struct JoinedDefaultParameterRule {
  static let id = "joined_default_parameter"
  static let name = "Joined Default Parameter"
  static let summary = "Discouraged explicit usage of the default separator"
  static let isCorrectable = true
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let foo = bar.joined()"),
      Example("let foo = bar.joined(separator: \",\")"),
      Example("let foo = bar.joined(separator: toto)"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let foo = bar.joined(↓separator: \"\")"),
      Example(
        """
        let foo = bar.filter(toto)
                     .joined(↓separator: ""),
        """,
      ),
      Example(
        """
        func foo() -> String {
          return ["1", "2"].joined(↓separator: "")
        }
        """,
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("let foo = bar.joined(↓separator: \"\")"): Example("let foo = bar.joined()"),
      Example("let foo = bar.filter(toto)\n.joined(↓separator: \"\")"):
        Example("let foo = bar.filter(toto)\n.joined()"),
      Example("func foo() -> String {\n   return [\"1\", \"2\"].joined(↓separator: \"\")\n}"):
        Example("func foo() -> String {\n   return [\"1\", \"2\"].joined()\n}"),
      Example("class C {\n#if true\nlet foo = bar.joined(↓separator: \"\")\n#endif\n}"):
        Example("class C {\n#if true\nlet foo = bar.joined()\n#endif\n}"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension JoinedDefaultParameterRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension JoinedDefaultParameterRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let violationPosition = node.violationPosition {
        violations.append(violationPosition)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.violationPosition != nil else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newNode = node.with(\.arguments, [])
      return super.visit(newNode)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var violationPosition: AbsolutePosition? {
    guard let argument = arguments.first,
      let memberExp = calledExpression.as(MemberAccessExprSyntax.self),
      memberExp.declName.baseName.text == "joined",
      argument.label?.text == "separator",
      let strLiteral = argument.expression.as(StringLiteralExprSyntax.self),
      strLiteral.isEmptyString
    else {
      return nil
    }

    return argument.positionAfterSkippingLeadingTrivia
  }
}
