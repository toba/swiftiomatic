import SwiftSyntax

struct FatalErrorMessageRule {
    static let id = "fatal_error_message"
    static let name = "Fatal Error Message"
    static let summary = "A fatalError call should have a message"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                """
                func foo() {
                  fatalError("Foo")
                }
                """,
            ),
            Example(
                """
                func foo() {
                  fatalError(x)
                }
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                func foo() {
                  ↓fatalError("")
                }
                """,
            ),
            Example(
                """
                func foo() {
                  ↓fatalError()
                }
                """,
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension FatalErrorMessageRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension FatalErrorMessageRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let expression = node.calledExpression.as(DeclReferenceExprSyntax.self),
                  expression.baseName.text == "fatalError",
                  node.arguments.isEmptyOrEmptyString
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

extension LabeledExprListSyntax {
    fileprivate var isEmptyOrEmptyString: Bool {
        if isEmpty {
            return true
        }
        return count == 1
            && first?.expression.as(StringLiteralExprSyntax.self)?
            .isEmptyString == true
    }
}
