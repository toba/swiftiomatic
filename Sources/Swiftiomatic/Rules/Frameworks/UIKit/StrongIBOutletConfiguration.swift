struct StrongIBOutletConfiguration: RuleConfiguration {
    let id = "strong_iboutlet"
    let name = "Strong IBOutlet"
    let summary = "@IBOutlets shouldn't be declared as weak"
    let isCorrectable = true
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
              Self.wrapExample("@IBOutlet var label: UILabel?"),
              Self.wrapExample("weak var label: UILabel?"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              Self.wrapExample("@IBOutlet ↓weak var label: UILabel?"),
              Self.wrapExample("@IBOutlet ↓unowned var label: UILabel!"),
              Self.wrapExample("@IBOutlet ↓weak var textField: UITextField?"),
            ]
    }
    var corrections: [Example: Example] {
        [
              Self.wrapExample("@IBOutlet ↓weak var label: UILabel?"):
                Self.wrapExample("@IBOutlet var label: UILabel?"),
              Self.wrapExample("@IBOutlet ↓unowned var label: UILabel!"):
                Self.wrapExample("@IBOutlet var label: UILabel!"),
              Self.wrapExample("@IBOutlet ↓weak var textField: UITextField?"):
                Self.wrapExample("@IBOutlet var textField: UITextField?"),
            ]
    }
}
