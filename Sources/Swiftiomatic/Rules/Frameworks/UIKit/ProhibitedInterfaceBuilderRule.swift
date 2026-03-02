import SwiftSyntax

struct ProhibitedInterfaceBuilderRule {
    static let id = "prohibited_interface_builder"
    static let name = "Prohibited Interface Builder"
    static let summary = "Creating views using Interface Builder should be avoided"
    static let isOptIn = true

    private static func wrapExample(_ text: String, file: StaticString = #filePath, line: UInt = #line)
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

    static var nonTriggeringExamples: [Example] {
        [
              Self.wrapExample("var label: UILabel!"),
              Self.wrapExample("@objc func buttonTapped(_ sender: UIButton) {}"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Self.wrapExample("@IBOutlet ↓var label: UILabel!"),
              Self.wrapExample("@IBAction ↓func buttonTapped(_ sender: UIButton) {}"),
            ]
    }
  var options = SeverityOption<Self>(.warning)

}

extension ProhibitedInterfaceBuilderRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

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
