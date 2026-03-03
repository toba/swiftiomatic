import SwiftSyntax

struct ContainsOverFirstNotNilRule {
    static let id = "contains_over_first_not_nil"
    static let name = "Contains over First not Nil"
    static let summary =
        "Prefer `contains` over `first(where:) != nil` and `firstIndex(where:) != nil`."
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        ["first", "firstIndex"].flatMap { method in
            [
                Example("let \(method) = myList.\(method)(where: { $0 % 2 == 0 })"),
                Example("let \(method) = myList.\(method) { $0 % 2 == 0 }"),
            ]
        }
    }

    static var triggeringExamples: [Example] {
        ["first", "firstIndex"].flatMap { method in
            ["!=", "=="].flatMap { comparison in
                [
                    Example("↓myList.\(method) { $0 % 2 == 0 } \(comparison) nil"),
                    Example("↓myList.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil"),
                    Example(
                        "↓myList.map { $0 + 1 }.\(method)(where: { $0 % 2 == 0 }) \(comparison) nil",
                    ),
                    Example("↓myList.\(method)(where: someFunction) \(comparison) nil"),
                    Example("↓myList.map { $0 + 1 }.\(method) { $0 % 2 == 0 } \(comparison) nil"),
                    Example("(↓myList.\(method) { $0 % 2 == 0 }) \(comparison) nil"),
                ]
            }
        }
    }

    var options = SeverityOption<Self>(.warning)
}

extension ContainsOverFirstNotNilRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension ContainsOverFirstNotNilRule {
    func preprocess(file: SwiftSource) -> SourceFileSyntax? {
        file.foldedSyntaxTree
    }
}

extension ContainsOverFirstNotNilRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
                  operatorNode.operator.tokenKind.isEqualityComparison,
                  node.rightOperand.is(NilLiteralExprSyntax.self),
                  let first = node.leftOperand.asFunctionCall,
                  let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
                  ["first", "firstIndex"].contains(calledExpression.declName.baseName.text)
            else {
                return
            }

            let violation = SyntaxViolation(
                position: first.positionAfterSkippingLeadingTrivia,
                reason:
                "Prefer `contains` over `\(calledExpression.declName.baseName.text)(where:) != nil`",
            )
            violations.append(violation)
        }
    }
}
