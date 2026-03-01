import SwiftSyntax

struct ApplicationMainRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ApplicationMainConfiguration()

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
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ApplicationMainRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AttributeSyntax) {
      let name = node.attributeName.trimmedDescription
      if name == "UIApplicationMain" || name == "NSApplicationMain" {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
