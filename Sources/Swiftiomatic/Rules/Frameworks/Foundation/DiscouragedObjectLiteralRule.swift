import SwiftSyntax

struct DiscouragedObjectLiteralRule: Rule {
  var configuration = DiscouragedObjectLiteralConfiguration()

  static let description = RuleDescription(
    identifier: "discouraged_object_literal",
    name: "Discouraged Object Literal",
    description: "Prefer initializers over object literals",
    kind: .idiomatic,
    nonTriggeringExamples: [
      Example("let image = UIImage(named: aVariable)"),
      Example("let image = UIImage(named: \"interpolated \\(variable)\")"),
      Example("let color = UIColor(red: value, green: value, blue: value, alpha: 1)"),
      Example("let image = NSImage(named: aVariable)"),
      Example("let image = NSImage(named: \"interpolated \\(variable)\")"),
      Example("let color = NSColor(red: value, green: value, blue: value, alpha: 1)"),
    ],
    triggeringExamples: [
      Example("let image = ↓#imageLiteral(resourceName: \"image.jpg\")"),
      Example(
        "let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
      ),
    ],
  )
}

extension DiscouragedObjectLiteralRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension DiscouragedObjectLiteralRule: OptInRule {}

extension DiscouragedObjectLiteralRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
