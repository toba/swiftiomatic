import SwiftSyntax

struct ProhibitedInterfaceBuilderRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ProhibitedInterfaceBuilderConfiguration()

  static let description = RuleDescription(
    identifier: "prohibited_interface_builder",
    name: "Prohibited Interface Builder",
    description: "Creating views using Interface Builder should be avoided",
    isOptIn: true,
    nonTriggeringExamples: [
      wrapExample("var label: UILabel!"),
      wrapExample("@objc func buttonTapped(_ sender: UIButton) {}"),
    ],
    triggeringExamples: [
      wrapExample("@IBOutlet ↓var label: UILabel!"),
      wrapExample("@IBAction ↓func buttonTapped(_ sender: UIButton) {}"),
    ],
  )
}

extension ProhibitedInterfaceBuilderRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ProhibitedInterfaceBuilderRule {}

extension ProhibitedInterfaceBuilderRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      if node.isIBOutlet {
        violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      if node.isIBAction {
        violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
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
