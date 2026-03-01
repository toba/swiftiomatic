import SwiftSyntax

struct MultilineCallArgumentsRule {
  var configuration = MultilineCallArgumentsConfiguration()

  static let description = RuleDescription(
    identifier: "multiline_call_arguments",
    name: "Multiline Call Arguments",
    description: "Call should have each parameter on a separate line",
    isOptIn: true,
    nonTriggeringExamples: [
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
    ],
    triggeringExamples: [
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
    ],
  )
}

extension MultilineCallArgumentsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension MultilineCallArgumentsRule {}

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
