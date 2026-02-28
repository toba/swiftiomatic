import SwiftSyntax

struct XCTFailMessageRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "xctfail_message",
        name: "XCTFail Message",
        description: "An XCTFail call should include a description of the assertion",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example(
                """
                func testFoo() {
                  XCTFail("bar")
                }
                """
            ),
            Example(
                """
                func testFoo() {
                  XCTFail(bar)
                }
                """
            ),
        ],
        triggeringExamples: [
            Example(
                """
                func testFoo() {
                  ↓XCTFail()
                }
                """
            ),
            Example(
                """
                func testFoo() {
                  ↓XCTFail("")
                }
                """
            ),
        ]
    )
}

extension XCTFailMessageRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

private extension XCTFailMessageRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let expression = node.calledExpression.as(DeclReferenceExprSyntax.self),
                expression.baseName.text == "XCTFail",
                node.arguments.isEmptyOrEmptyString
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension LabeledExprListSyntax {
    var isEmptyOrEmptyString: Bool {
        if isEmpty {
            return true
        }
        return count == 1 && first?.expression.as(StringLiteralExprSyntax.self)?.isEmptyString == true
    }
}
