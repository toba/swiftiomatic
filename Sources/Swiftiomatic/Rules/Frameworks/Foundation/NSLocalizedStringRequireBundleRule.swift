import SwiftSyntax

struct NSLocalizedStringRequireBundleRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "nslocalizedstring_require_bundle",
    name: "NSLocalizedString Require Bundle",
    description:
      "Calls to NSLocalizedString should specify the bundle which contains the strings file",
    isOptIn: true,
    nonTriggeringExamples: [
      Example(
        """
        NSLocalizedString("someKey", bundle: .main, comment: "test")
        """,
      ),
      Example(
        """
        NSLocalizedString("someKey", tableName: "a",
                          bundle: Bundle(for: A.self),
                          comment: "test")
        """,
      ),
      Example(
        """
        NSLocalizedString("someKey", tableName: "xyz",
                          bundle: someBundle, value: "test"
                          comment: "test")
        """,
      ),
      Example(
        """
        arbitraryFunctionCall("something")
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        ↓NSLocalizedString("someKey", comment: "test")
        """,
      ),
      Example(
        """
        ↓NSLocalizedString("someKey", tableName: "a", comment: "test")
        """,
      ),
      Example(
        """
        ↓NSLocalizedString("someKey", tableName: "xyz",
                          value: "test", comment: "test")
        """,
      ),
    ],
  )
}

extension NSLocalizedStringRequireBundleRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NSLocalizedStringRequireBundleRule {}

extension NSLocalizedStringRequireBundleRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
        identifierExpr.baseName.tokenKind == .identifier("NSLocalizedString"),
        !node.arguments.containsArgument(named: "bundle")
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension LabeledExprListSyntax {
  fileprivate func containsArgument(named name: String) -> Bool {
    contains { arg in
      arg.label?.tokenKind == .identifier(name)
    }
  }
}
