import SwiftSyntax

struct ConditionalReturnsOnNewlineRule {
    static let id = "conditional_returns_on_newline"
    static let name = "Conditional Returns on Newline"
    static let summary = "Conditional statements should always return on the next line"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("guard true else {\n return true\n}"),
            Example("guard true,\n let x = true else {\n return true\n}"),
            Example("if true else {\n return true\n}"),
            Example("if true,\n let x = true else {\n return true\n}"),
            Example("if textField.returnKeyType == .Next {"),
            Example("if true { // return }"),
            Example(
                """
                guard something
                else { return }
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("↓guard true else { return }"),
            Example("↓if true { return }"),
            Example("↓if true { break } else { return }"),
            Example("↓if true { break } else {       return }"),
            Example("↓if true { return \"YES\" } else { return \"NO\" }"),
            Example(
                """
                ↓guard condition else { XCTFail(); return }
                """,
            ),
        ]
    }

    var options = ConditionalReturnsOnNewlineOptions()
}

extension ConditionalReturnsOnNewlineRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension ConditionalReturnsOnNewlineRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: IfExprSyntax) {
            if isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.ifKeyword) {
                violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
                return
            }

            if let elseBody = node.elseBody?.as(CodeBlockSyntax.self),
               let elseKeyword = node.elseKeyword,
               isReturn(elseBody.statements.lastReturn, onTheSameLineAs: elseKeyword)
            {
                violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            if configuration.ifOnly {
                return
            }

            if isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.guardKeyword) {
                violations.append(node.guardKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        private func isReturn(_ returnStmt: ReturnStmtSyntax?, onTheSameLineAs token: TokenSyntax)
            -> Bool
        {
            guard let returnStmt else {
                return false
            }

            return locationConverter.location(
                for: returnStmt.returnKeyword.positionAfterSkippingLeadingTrivia,
            ).line == locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line
        }
    }
}

extension CodeBlockItemListSyntax {
    fileprivate var lastReturn: ReturnStmtSyntax? {
        last?.item.as(ReturnStmtSyntax.self)
    }
}
