import SwiftSyntax

struct RedundantBackticksRule {
    static let id = "redundant_backticks"
    static let name = "Redundant Backticks"
    static let summary =
        "Backtick-escaped identifiers that are not keywords in their context are redundant"
    static let scope: Scope = .format
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("let `class` = \"value\""),
            Example("func `init`() {}"),
            Example("let `self` = this"),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("let ↓`foo` = bar"),
            Example("func ↓`myFunc`() {}"),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example("let ↓`foo` = bar"): Example("let foo = bar"),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension RedundantBackticksRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension RedundantBackticksRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: TokenSyntax) {
            guard node.hasRedundantBackticks else { return }
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visitAny(_ node: Syntax) -> Syntax? {
            if let result = super.visitAny(node) { return result }
            guard let token = node.as(TokenSyntax.self), token.hasRedundantBackticks else {
                return nil
            }
            numberOfCorrections += 1
            return Syntax(
                token.with(\.tokenKind, .identifier(token.identifier?.name ?? token.text)),
            )
        }
    }
}

extension TokenSyntax {
    fileprivate var hasRedundantBackticks: Bool {
        // Only applies to backtick-escaped identifiers
        guard case let .identifier(name) = tokenKind,
              text.hasPrefix("`"), text.hasSuffix("`")
        else {
            return false
        }
        // If the unescaped name is a keyword, backticks are needed
        return !name.isSwiftKeyword
    }
}
