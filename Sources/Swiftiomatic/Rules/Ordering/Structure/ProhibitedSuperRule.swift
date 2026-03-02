import SwiftSyntax

struct ProhibitedSuperRule {
  var options = ProhibitedSuperOptions()

  static let configuration = ProhibitedSuperConfiguration()
}

extension ProhibitedSuperRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ProhibitedSuperRule {}

extension ProhibitedSuperRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      guard let ctx = node.superCallContext(matchingMethodNames: configuration.resolvedMethodNames),
        ctx.callCount > 0
      else {
        return
      }

      violations.append(
        SyntaxViolation(
          position: ctx.body.leftBrace.endPositionBeforeTrailingTrivia,
          reason: "Method '\(ctx.name)' should not call to super function",
        ),
      )
    }
  }
}
