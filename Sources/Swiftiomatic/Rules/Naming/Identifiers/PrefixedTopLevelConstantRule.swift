import SwiftSyntax

struct PrefixedTopLevelConstantRule {
  var options = PrefixedTopLevelConstantOptions()

  static let configuration = PrefixedTopLevelConstantConfiguration()
}

extension PrefixedTopLevelConstantRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PrefixedTopLevelConstantRule {}

extension PrefixedTopLevelConstantRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private let topLevelPrefix = "k"

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      guard node.bindingSpecifier.tokenKind == .keyword(.let) else {
        return
      }

      if configuration.onlyPrivateMembers, !node.modifiers.containsPrivateOrFileprivate() {
        return
      }

      for binding in node.bindings {
        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          !pattern.identifier.text.hasPrefix(topLevelPrefix)
        else {
          continue
        }

        violations.append(binding.pattern.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
      .skipChildren
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
      .skipChildren
    }
  }
}
