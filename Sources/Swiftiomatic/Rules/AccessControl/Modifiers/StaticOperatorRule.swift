import SwiftSyntax

struct StaticOperatorRule {
    var options = SeverityConfiguration<Self>(.warning)

    static let configuration = StaticOperatorConfiguration()
}

extension StaticOperatorRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension StaticOperatorRule {}

extension StaticOperatorRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            .all
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.isFreeFunction, node.isOperator {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

extension FunctionDeclSyntax {
    fileprivate var isFreeFunction: Bool {
        parent?.is(CodeBlockItemSyntax.self) ?? false
    }

    fileprivate var isOperator: Bool {
        switch name.tokenKind {
            case .binaryOperator:
                return true
            default:
                return false
        }
    }
}
