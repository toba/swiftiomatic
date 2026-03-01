import SwiftSyntax

struct PreferFinalClassesRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "prefer_final_classes",
    name: "Prefer Final Classes",
    description: "Classes should be marked `final` unless designed for subclassing",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("final class Foo {}"),
      Example("open class Foo {}"),
      Example("class Foo: NSObject {}"),
      Example(
        """
        /// Base class for all handlers
        class BaseHandler {}
        """,
      ),
    ],
    triggeringExamples: [
      Example("↓class Foo {}"),
      Example("↓class Foo { func bar() {} }"),
    ],
  )
}

extension PreferFinalClassesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension PreferFinalClassesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClassDeclSyntax) {
      // Skip if already final or open
      let hasFinal = node.modifiers.contains { $0.name.tokenKind == .keyword(.final) }
      let hasOpen = node.modifiers.contains { $0.name.tokenKind == .keyword(.open) }
      guard !hasFinal, !hasOpen else { return }

      // Skip classes named "Base*" or with doc comments mentioning subclassing
      let name = node.name.text
      if name.hasPrefix("Base") || name.hasSuffix("Base") { return }

      if let leadingTrivia = node.leadingTrivia.pieces.first(where: {
        if case .docLineComment(let text) = $0 { return text.lowercased().contains("subclass") }
        if case .docBlockComment(let text) = $0 { return text.lowercased().contains("subclass") }
        return false
      }) {
        _ = leadingTrivia
        return
      }

      violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
