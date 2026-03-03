import SwiftSyntax

struct LastWhereRule {
    static let id = "last_where"
    static let name = "Last Where"
    static let summary = "Prefer using `.last(where:)` over `.filter { }.last` in collections"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("kinds.filter(excludingKinds.contains).isEmpty && kinds.last == .identifier"),
            Example("myList.last(where: { $0 % 2 == 0 })"),
            Example("match(pattern: pattern).filter { $0.last == .identifier }"),
            Example("(myList.filter { $0 == 1 }.suffix(2)).last"),
            Example(#"collection.filter("stringCol = '3'").last"#),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("↓myList.filter { $0 % 2 == 0 }.last"),
            Example("↓myList.filter({ $0 % 2 == 0 }).last"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last"),
            Example("↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last?.something()"),
            Example("↓myList.filter(someFunction).last"),
            Example("↓myList.filter({ $0 % 2 == 0 })\n.last"),
            Example("(↓myList.filter { $0 == 1 }).last"),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension LastWhereRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension LastWhereRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                node.declName.baseName.text == "last",
                let functionCall = node.base?.asFunctionCall,
                let calledExpression = functionCall.calledExpression
                .as(MemberAccessExprSyntax.self),
                calledExpression.declName.baseName.text == "filter",
                !functionCall.arguments.contains(where: \.expression.shouldSkip)
            else {
                return
            }

            violations.append(functionCall.positionAfterSkippingLeadingTrivia)
        }
    }
}

extension ExprSyntax {
    fileprivate var shouldSkip: Bool {
        if `is`(StringLiteralExprSyntax.self) {
            return true
        }
        if let functionCall = `as`(FunctionCallExprSyntax.self),
           let calledExpression = functionCall.calledExpression.as(DeclReferenceExprSyntax.self),
           calledExpression.baseName.text == "NSPredicate"
        {
            return true
        }
        return false
    }
}
