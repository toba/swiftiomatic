import SwiftiomaticSyntax

struct OptionalEnumCaseMatchingRule {
  static let id = "optional_enum_case_matching"
  static let name = "Optional Enum Case Match"
  static let summary =
    "Matching an enum case against an optional enum without '?' is supported on Swift 5.1 and above"
  static let isCorrectable = true
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        switch foo {
         case .bar: break
         case .baz: break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case (.bar, .baz): break
         case (.bar, _): break
         case (_, .baz): break
         default: break
        }
        """,
      ),
      Example(
        """
        switch (x, y) {
        case (.c, _?):
            break
        case (.c, nil):
            break
        case (_, _):
            break
        }
        """,
      ),
      // https://github.com/apple/swift/issues/61817
      Example(
        """
        switch bool {
        case true?:
          break
        case false?:
          break
        case .none:
          break
        }
        """, isExcludedFromDocumentation: true,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        switch foo {
         case .bar↓?: break
         case .baz: break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case Foo.bar↓?: break
         case .baz: break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case .bar↓?, .baz↓?: break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case .bar↓? where x > 1: break
         case .baz: break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case (.bar↓?, .baz↓?): break
         case (.bar↓?, _): break
         case (_, .bar↓?): break
         default: break
        }
        """,
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        switch foo {
         case .bar↓?: break
         case .baz: break
         default: break
        }
        """,
      ): Example(
        """
        switch foo {
         case .bar: break
         case .baz: break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case Foo.bar↓?: break
         case .baz: break
         default: break
        }
        """,
      ): Example(
        """
        switch foo {
         case Foo.bar: break
         case .baz: break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case .bar↓?, .baz↓?: break
         default: break
        }
        """,
      ): Example(
        """
        switch foo {
         case .bar, .baz: break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case .bar↓? where x > 1: break
         case .baz: break
         default: break
        }
        """,
      ): Example(
        """
        switch foo {
         case .bar where x > 1: break
         case .baz: break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case (.bar↓?, .baz↓?): break
         case (.bar↓?, _): break
         case (_, .bar↓?): break
         default: break
        }
        """,
      ): Example(
        """
        switch foo {
         case (.bar, .baz): break
         case (.bar, _): break
         case (_, .bar): break
         default: break
        }
        """,
      ),
      Example(
        """
        switch foo {
         case (true?, false?): break
         case (true?, _): break
         case (_, false?): break
         default: break
        }
        """,
      ): Example(
        """
        switch foo {
         case (true?, false?): break
         case (true?, _): break
         case (_, false?): break
         default: break
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension OptionalEnumCaseMatchingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension OptionalEnumCaseMatchingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: SwitchCaseItemSyntax) {
      guard let pattern = node.pattern.as(ExpressionPatternSyntax.self) else {
        return
      }

      if let expression = pattern.expression.as(OptionalChainingExprSyntax.self),
        !expression.expression.isDiscardAssignmentOrBoolLiteral
      {
        violations.append(expression.questionMark.positionAfterSkippingLeadingTrivia)
      } else if let expression = pattern.expression.as(TupleExprSyntax.self) {
        let optionalChainingExpressions = expression.optionalChainingExpressions()
        for optionalChainingExpression in optionalChainingExpressions {
          violations.append(
            optionalChainingExpression.questionMark.positionAfterSkippingLeadingTrivia,
          )
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
      guard
        let pattern = node.pattern.as(ExpressionPatternSyntax.self),
        pattern.expression.is(OptionalChainingExprSyntax.self)
          || pattern.expression.is(TupleExprSyntax.self)
      else {
        return super.visit(node)
      }

      if let expression = pattern.expression.as(OptionalChainingExprSyntax.self),
        !expression.expression.isDiscardAssignmentOrBoolLiteral
      {
        numberOfCorrections += 1
        let newPattern = PatternSyntax(pattern.with(\.expression, expression.expression))
        let newNode =
          node
          .with(\.pattern, newPattern)
          .with(
            \.whereClause,
            node.whereClause?.with(
              \.leadingTrivia,
              expression.questionMark.trailingTrivia,
            ),
          )
        return super.visit(newNode)
      }
      if let expression = pattern.expression.as(TupleExprSyntax.self) {
        var newExpression = expression
        for element in expression.elements {
          guard
            let optionalChainingExpression = element.expression
              .as(OptionalChainingExprSyntax.self),
            !optionalChainingExpression.expression.isDiscardAssignmentOrBoolLiteral
          else {
            continue
          }
          numberOfCorrections += 1
          let newElement = element.with(
            \.expression,
            optionalChainingExpression.expression,
          )
          if let index = expression.elements.index(of: element) {
            newExpression.elements = newExpression.elements.with(\.[index], newElement)
          }
        }

        let newPattern = PatternSyntax(
          pattern.with(
            \.expression,
            ExprSyntax(newExpression),
          ),
        )
        let newNode = node.with(\.pattern, newPattern)
        return super.visit(newNode)
      }

      return super.visit(node)
    }
  }
}

extension TupleExprSyntax {
  fileprivate func optionalChainingExpressions() -> [OptionalChainingExprSyntax] {
    elements
      .compactMap { $0.expression.as(OptionalChainingExprSyntax.self) }
      .filter { !$0.expression.isDiscardAssignmentOrBoolLiteral }
  }
}

extension ExprSyntax {
  fileprivate var isDiscardAssignmentOrBoolLiteral: Bool {
    `is`(DiscardAssignmentExprSyntax.self) || `is`(BooleanLiteralExprSyntax.self)
  }
}
