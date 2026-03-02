import SwiftSyntax

struct DiscouragedObjectLiteralRule {
  var options = DiscouragedObjectLiteralOptions()

  static let configuration = DiscouragedObjectLiteralConfiguration()
}

extension DiscouragedObjectLiteralRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DiscouragedObjectLiteralRule {}

extension DiscouragedObjectLiteralRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MacroExpansionExprSyntax) {
      guard
        case .identifier(let identifierText) = node.macroName.tokenKind,
        ["colorLiteral", "imageLiteral"].contains(identifierText)
      else {
        return
      }

      if !configuration.imageLiteral, identifierText == "imageLiteral" {
        return
      }

      if !configuration.colorLiteral, identifierText == "colorLiteral" {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
