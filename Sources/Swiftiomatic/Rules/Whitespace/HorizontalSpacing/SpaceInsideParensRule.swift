import SwiftSyntax

struct SpaceInsideParensRule {
    static let id = "space_inside_parens"
    static let name = "Space Inside Parentheses"
    static let summary = "There should be no spaces immediately inside parentheses"
    static let scope: Scope = .format
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("(a, b)"),
            Example("foo(bar)"),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("(↓ a, b)"),
            Example("foo(↓ bar )"),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example("(↓ a, b )"): Example("(a, b )"),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension SpaceInsideParensRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension SpaceInsideParensRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
            switch token.tokenKind {
                case .leftParen:
                    if token.trailingTrivia.isHorizontalWhitespaceOnly {
                        violations.append(token.endPositionBeforeTrailingTrivia)
                    }
                case .rightParen:
                    if token.leadingTrivia.isHorizontalWhitespaceOnly {
                        violations.append(token.positionAfterSkippingLeadingTrivia)
                    }
                default:
                    break
            }
            return .visitChildren
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ token: TokenSyntax) -> TokenSyntax {
            switch token.tokenKind {
                case .leftParen:
                    if token.trailingTrivia.isHorizontalWhitespaceOnly {
                        numberOfCorrections += 1
                        return super.visit(token.with(\.trailingTrivia, Trivia()))
                    }
                case .rightParen:
                    if token.leadingTrivia.isHorizontalWhitespaceOnly {
                        numberOfCorrections += 1
                        return super.visit(token.with(\.leadingTrivia, Trivia()))
                    }
                default:
                    break
            }
            return super.visit(token)
        }
    }
}
