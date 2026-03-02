import SwiftSyntax

struct PreferFinalClassesRule {
    static let id = "prefer_final_classes"
    static let name = "Prefer Final Classes"
    static let summary = "Classes should be marked `final` unless designed for subclassing"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
              Example("final class Foo {}"),
              Example("open class Foo {}"),
              Example("class Foo: NSObject {}"),
              Example(
                """
                /// Base class for all handlers
                class BaseHandler {}
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("↓class Foo {}"),
              Example("↓class Foo { func bar() {} }"),
            ]
    }
  var options = SeverityOption<Self>(.warning)

}

extension PreferFinalClassesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
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
