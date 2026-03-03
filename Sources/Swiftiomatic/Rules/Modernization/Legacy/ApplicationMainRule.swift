import SwiftSyntax

struct ApplicationMainRule {
    static let id = "application_main"
    static let name = "Application Main"
    static let summary = "Replace `@UIApplicationMain` and `@NSApplicationMain` with `@main`"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                """
                @main
                class AppDelegate: UIResponder, UIApplicationDelegate {}
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                ↓@UIApplicationMain
                class AppDelegate: UIResponder, UIApplicationDelegate {}
                """,
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension ApplicationMainRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension ApplicationMainRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: AttributeSyntax) {
            let name = node.attributeName.trimmedDescription
            if name == "UIApplicationMain" || name == "NSApplicationMain" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
