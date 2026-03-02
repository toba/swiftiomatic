import SwiftSyntax

struct PreferFinalClassesRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PreferFinalClassesConfiguration()
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
