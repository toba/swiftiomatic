import SwiftSyntax

struct DiscouragedObjectLiteralRule {
    static let id = "discouraged_object_literal"
    static let name = "Discouraged Object Literal"
    static let summary = "Prefer initializers over object literals"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("let image = UIImage(named: aVariable)"),
              Example("let image = UIImage(named: \"interpolated \\(variable)\")"),
              Example("let color = UIColor(red: value, green: value, blue: value, alpha: 1)"),
              Example("let image = NSImage(named: aVariable)"),
              Example("let image = NSImage(named: \"interpolated \\(variable)\")"),
              Example("let color = NSColor(red: value, green: value, blue: value, alpha: 1)"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("let image = ↓#imageLiteral(resourceName: \"image.jpg\")"),
              Example(
                "let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
              ),
            ]
    }
  var options = DiscouragedObjectLiteralOptions()

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
