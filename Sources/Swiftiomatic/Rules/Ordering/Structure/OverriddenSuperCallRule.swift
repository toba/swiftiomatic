import SwiftSyntax

struct OverriddenSuperCallRule {
  var options = OverriddenSuperCallOptions()

  static let configuration = OverriddenSuperCallConfiguration()
}

extension OverriddenSuperCallRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension OverriddenSuperCallRule {}

extension OverriddenSuperCallRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      guard let ctx = node.superCallContext(matchingMethodNames: configuration.resolvedMethodNames)
      else {
        return
      }

      if ctx.callCount == 0 {
        violations.append(
          SyntaxViolation(
            position: ctx.body.leftBrace.endPositionBeforeTrailingTrivia,
            reason: "Method '\(ctx.name)' should call to super function",
          ),
        )
      } else if ctx.callCount > 1 {
        violations.append(
          SyntaxViolation(
            position: ctx.body.leftBrace.endPositionBeforeTrailingTrivia,
            reason: "Method '\(ctx.name)' should call to super only once",
          ),
        )
      }
    }
  }
}
