import SwiftSyntax

struct ApplicationMainRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "application_main",
    name: "Application Main",
    description:
      "Replace `@UIApplicationMain` and `@NSApplicationMain` with `@main`",
    scope: .suggest,
    nonTriggeringExamples: [
      Example(
        """
        @main
        class AppDelegate: UIResponder, UIApplicationDelegate {}
        """),
    ],
    triggeringExamples: [
      Example(
        """
        ↓@UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {}
        """),
    ],
  )
}

extension ApplicationMainRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension ApplicationMainRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: AttributeSyntax) {
      let name = node.attributeName.trimmedDescription
      if name == "UIApplicationMain" || name == "NSApplicationMain" {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
