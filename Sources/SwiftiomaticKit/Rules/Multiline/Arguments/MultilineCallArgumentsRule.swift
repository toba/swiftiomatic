import SwiftiomaticSyntax

struct MultilineCallArgumentsRule {
  static let id = "multiline_call_arguments"
  static let name = "Multiline Call Arguments"
  static let summary = "Call should have each parameter on a separate line"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        foo(
        param1: "param1",
            param2: false,
            param3: []
        )
        """,
        configuration: ["max_number_of_single_line_parameters": 2],
      ),
      Example(
        """
        foo(param1: 1,
            param2: false,
            param3: [])
        """,
        configuration: ["max_number_of_single_line_parameters": 1],
      ),
      Example(
        "foo(param1: 1, param2: false)",
        configuration: ["max_number_of_single_line_parameters": 2],
      ),
      Example(
        "Enum.foo(param1: 1, param2: false)",
        configuration: ["max_number_of_single_line_parameters": 2],
      ),
      Example("foo(param1: 1)", configuration: ["allows_single_line": false]),
      Example("Enum.foo(param1: 1)", configuration: ["allows_single_line": false]),
      Example(
        "Enum.foo(param1: 1, param2: 2, param3: 3)",
        configuration: ["allows_single_line": true],
      ),
      Example(
        """
        foo(
            param1: 1,
            param2: 2,
            param3: 3
        )
        """,
        configuration: ["allows_single_line": false],
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        "↓foo(param1: 1, param2: false, param3: [])",
        configuration: ["max_number_of_single_line_parameters": 2],
      ),
      Example(
        "↓Enum.foo(param1: 1, param2: false, param3: [])",
        configuration: ["max_number_of_single_line_parameters": 2],
      ),
      Example(
        """
        ↓foo(param1: 1, param2: false,
                param3: [])
        """,
        configuration: ["max_number_of_single_line_parameters": 3],
      ),
      Example(
        """
        ↓Enum.foo(param1: 1, param2: false,
                param3: [])
        """,
        configuration: ["max_number_of_single_line_parameters": 3],
      ),
      Example("↓foo(param1: 1, param2: false)", configuration: ["allows_single_line": false]),
      Example(
        "↓Enum.foo(param1: 1, param2: false)",
        configuration: ["allows_single_line": false],
      ),
    ]
  }

  var options = MultilineCallArgumentsOptions()
}

extension MultilineCallArgumentsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MultilineCallArgumentsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if containsViolation(
        parameterPositions: node.arguments.map(\.positionAfterSkippingLeadingTrivia),
      ) {
        violations.append(node.calledExpression.positionAfterSkippingLeadingTrivia)
      }
    }

    private func containsViolation(parameterPositions: [AbsolutePosition]) -> Bool {
      containsMultilineViolation(
        positions: parameterPositions,
        locationConverter: locationConverter,
        allowsSingleLine: configuration.allowsSingleLine,
        maxSingleLine: configuration.maxNumberOfSingleLineParameters,
      )
    }
  }
}
