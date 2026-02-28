import SwiftSyntax

struct AnonymousArgumentInMultilineClosureRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "anonymous_argument_in_multiline_closure",
    name: "Anonymous Argument in Multiline Closure",
    description: "Use named arguments in multiline closures",
    rationale: """
      In multiline closures, for clarity, prefer using named arguments

      ```
      closure { arg in
          print(arg)
      }
      ```

      to anonymous arguments

      ```
      closure {
          print(↓$0)
      }
      ```
      """,
    kind: .idiomatic,
    nonTriggeringExamples: [
      Example("closure { $0 }"),
      Example("closure { print($0) }"),
      Example(
        """
        closure { arg in
            print(arg)
        }
        """,
      ),
      Example(
        """
        closure { arg in
            nestedClosure { $0 + arg }
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        closure {
            print(↓$0)
        }
        """,
      )
    ],
  )
}

extension AnonymousArgumentInMultilineClosureRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension AnonymousArgumentInMultilineClosureRule: OptInRule {}

extension AnonymousArgumentInMultilineClosureRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
      let startLocation = locationConverter.location(
        for: node.leftBrace.positionAfterSkippingLeadingTrivia,
      )
      let endLocation = locationConverter.location(
        for: node.rightBrace.endPositionBeforeTrailingTrivia,
      )
      return startLocation.line == endLocation.line ? .skipChildren : .visitChildren
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      if case .dollarIdentifier = node.baseName.tokenKind {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
