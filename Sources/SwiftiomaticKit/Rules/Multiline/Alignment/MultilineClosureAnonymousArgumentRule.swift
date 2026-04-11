import SwiftSyntax

struct MultilineClosureAnonymousArgumentRule {
  static let id = "multiline_closure_anonymous_argument"
  static let name = "Multiline Closure Anonymous Argument"
  static let summary = "Use named arguments in multiline closures"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
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
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        closure {
            print(↓$0)
        }
        """,
      )
    ]
  }

  static let rationale: String? = """
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
    """
  var options = SeverityOption<Self>(.warning)
}

extension MultilineClosureAnonymousArgumentRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MultilineClosureAnonymousArgumentRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
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
