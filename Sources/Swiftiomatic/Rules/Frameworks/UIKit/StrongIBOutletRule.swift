import SwiftSyntax

struct StrongIBOutletRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = StrongIBOutletConfiguration()

  static let description = RuleDescription(
    identifier: "strong_iboutlet",
    name: "Strong IBOutlet",
    description: "@IBOutlets shouldn't be declared as weak",
    isOptIn: true,
    nonTriggeringExamples: [
      wrapExample("@IBOutlet var label: UILabel?"),
      wrapExample("weak var label: UILabel?"),
    ],
    triggeringExamples: [
      wrapExample("@IBOutlet ↓weak var label: UILabel?"),
      wrapExample("@IBOutlet ↓unowned var label: UILabel!"),
      wrapExample("@IBOutlet ↓weak var textField: UITextField?"),
    ],
    corrections: [
      wrapExample("@IBOutlet ↓weak var label: UILabel?"):
        wrapExample("@IBOutlet var label: UILabel?"),
      wrapExample("@IBOutlet ↓unowned var label: UILabel!"):
        wrapExample("@IBOutlet var label: UILabel!"),
      wrapExample("@IBOutlet ↓weak var textField: UITextField?"):
        wrapExample("@IBOutlet var textField: UITextField?"),
    ],
  )
}

extension StrongIBOutletRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension StrongIBOutletRule {}

extension StrongIBOutletRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      if let violationPosition = node.violationPosition {
        violations.append(violationPosition)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
      guard node.violationPosition != nil,
        let weakOrUnownedModifier = node.weakOrUnownedModifier,
        case let modifiers = node.modifiers
      else {
        return super.visit(node)
      }
      let newModifiers = modifiers.filter { $0 != weakOrUnownedModifier }
      let newNode = node.with(\.modifiers, newModifiers)
      numberOfCorrections += 1
      return super.visit(newNode)
    }
  }
}

extension VariableDeclSyntax {
  fileprivate var violationPosition: AbsolutePosition? {
    guard let keyword = weakOrUnownedKeyword, isIBOutlet else {
      return nil
    }

    return keyword.positionAfterSkippingLeadingTrivia
  }

  fileprivate var weakOrUnownedKeyword: TokenSyntax? {
    weakOrUnownedModifier?.name
  }
}

private func wrapExample(_ text: String, file: StaticString = #filePath, line: UInt = #line)
  -> Example
{
  Example(
    """
    class ViewController: UIViewController {
        \(text)
    }
    """, file: file, line: line,
  )
}
