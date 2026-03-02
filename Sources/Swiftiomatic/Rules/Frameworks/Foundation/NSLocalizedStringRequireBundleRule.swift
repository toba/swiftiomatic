import SwiftSyntax

struct NSLocalizedStringRequireBundleRule {
    static let id = "nslocalizedstring_require_bundle"
    static let name = "NSLocalizedString Require Bundle"
    static let summary = "Calls to NSLocalizedString should specify the bundle which contains the strings file"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
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
            ]
    }
    static var triggeringExamples: [Example] {
        [
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
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

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
