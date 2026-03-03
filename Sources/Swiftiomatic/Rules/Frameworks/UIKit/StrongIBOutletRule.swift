import SwiftSyntax

struct StrongIBOutletRule {
    static let id = "strong_iboutlet"
    static let name = "Strong IBOutlet"
    static let summary = "@IBOutlets shouldn't be declared as weak"
    static let isCorrectable = true
    static let isOptIn = true

    private static func wrapExample(
        _ text: String, file: StaticString = #filePath, line: UInt = #line,
    )
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
            wrapExample("@IBOutlet var label: UILabel?"),
            wrapExample("weak var label: UILabel?"),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            wrapExample("@IBOutlet ↓weak var label: UILabel?"),
            wrapExample("@IBOutlet ↓unowned var label: UILabel!"),
            wrapExample("@IBOutlet ↓weak var textField: UITextField?"),
        ]
    }

    static var corrections: [Example: Example] {
        [
            wrapExample("@IBOutlet ↓weak var label: UILabel?"):
                wrapExample("@IBOutlet var label: UILabel?"),
            wrapExample("@IBOutlet ↓unowned var label: UILabel!"):
                wrapExample("@IBOutlet var label: UILabel!"),
            wrapExample("@IBOutlet ↓weak var textField: UITextField?"):
                wrapExample("@IBOutlet var textField: UITextField?"),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension StrongIBOutletRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

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

    private var weakOrUnownedKeyword: TokenSyntax? {
        weakOrUnownedModifier?.name
    }
}
