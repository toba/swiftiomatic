import SwiftSyntax

struct NonOptionalStringDataConversionRule: Rule {
  var configuration = NonOptionalStringDataConversionConfiguration()

  private static let variablesIncluded = ["include_variables": true]

  static let description = RuleDescription(
    identifier: "non_optional_string_data_conversion",
    name: "Non-optional String -> Data Conversion",
    description: "Prefer non-optional `Data(_:)` initializer when converting `String` to `Data`",
    nonTriggeringExamples: [
      Example("Data(\"foo\".utf8)"),
      Example("Data(string.utf8)"),
      Example("\"foo\".data(using: .ascii)"),
      Example("string.data(using: .unicode)"),
      Example("Data(\"foo\".utf8)", configuration: variablesIncluded),
      Example("Data(string.utf8)", configuration: variablesIncluded),
      Example("\"foo\".data(using: .ascii)", configuration: variablesIncluded),
      Example("string.data(using: .unicode)", configuration: variablesIncluded),
    ],
    triggeringExamples: [
      Example("↓\"foo\".data(using: .utf8)"),
      Example("↓\"foo\".data(using: .utf8)", configuration: variablesIncluded),
      Example("↓string.data(using: .utf8)", configuration: variablesIncluded),
      Example("↓property.data(using: .utf8)", configuration: variablesIncluded),
      Example("↓obj.property.data(using: .utf8)", configuration: variablesIncluded),
      Example("↓getString().data(using: .utf8)", configuration: variablesIncluded),
      Example("↓getValue()?.data(using: .utf8)", configuration: variablesIncluded),
    ],
  )
}

extension NonOptionalStringDataConversionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension NonOptionalStringDataConversionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      if node.declName.baseName.text == "data",
        let parent = node.parent?.as(FunctionCallExprSyntax.self),
        let argument = parent.arguments.onlyElement,
        argument.label?.text == "using",
        argument.expression.as(MemberAccessExprSyntax.self)?.isUTF8 == true,
        let base = node.base,
        base.is(StringLiteralExprSyntax.self) || configuration.includeVariables
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension MemberAccessExprSyntax {
  fileprivate var isUTF8: Bool {
    declName.baseName.text == "utf8"
  }
}
