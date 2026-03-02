struct ProhibitedInterfaceBuilderConfiguration: RuleConfiguration {
    let id = "prohibited_interface_builder"
    let name = "Prohibited Interface Builder"
    let summary = "Creating views using Interface Builder should be avoided"
    let isOptIn = true

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

    var nonTriggeringExamples: [Example] {
        [
              Self.wrapExample("var label: UILabel!"),
              Self.wrapExample("@objc func buttonTapped(_ sender: UIButton) {}"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Self.wrapExample("@IBOutlet ↓var label: UILabel!"),
              Self.wrapExample("@IBAction ↓func buttonTapped(_ sender: UIButton) {}"),
            ]
    }
}
