import SwiftSyntax

struct EmptyParametersRule {
    static let id = "empty_parameters"
    static let name = "Empty Parameters"
    static let summary = "Prefer `() -> ` over `Void -> `"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("let abc: () -> Void = {}"),
            Example("func foo(completion: () -> Void)"),
            Example("func foo(completion: () throws -> Void)"),
            Example("let foo: (ConfigurationTests) -> Void throws -> Void)"),
            Example("let foo: (ConfigurationTests) ->   Void throws -> Void)"),
            Example("let foo: (ConfigurationTests) ->Void throws -> Void)"),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("let abc: ↓(Void) -> Void = {}"),
            Example("func foo(completion: ↓(Void) -> Void)"),
            Example("func foo(completion: ↓(Void) throws -> Void)"),
            Example("let foo: ↓(Void) -> () throws -> Void)"),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example("let abc: ↓(Void) -> Void = {}"): Example("let abc: () -> Void = {}"),
            Example("func foo(completion: ↓(Void) -> Void)"): Example(
                "func foo(completion: () -> Void)",
            ),
            Example("func foo(completion: ↓(Void) throws -> Void)"):
                Example("func foo(completion: () throws -> Void)"),
            Example("let foo: ↓(Void) -> () throws -> Void)"): Example(
                "let foo: () -> () throws -> Void)",
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension EmptyParametersRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension EmptyParametersRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: FunctionTypeSyntax) {
            guard let violationPosition = node.emptyParametersViolationPosition else {
                return
            }

            violations.append(violationPosition)
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
            guard node.emptyParametersViolationPosition != nil else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            return super.visit(node.with(\.parameters, TupleTypeElementListSyntax([])))
        }
    }
}

extension FunctionTypeSyntax {
    fileprivate var emptyParametersViolationPosition: AbsolutePosition? {
        guard
            let argument = parameters.onlyElement,
            leftParen.presence == .present,
            rightParen.presence == .present,
            let simpleType = argument.type.as(IdentifierTypeSyntax.self),
            simpleType.typeName == "Void"
        else {
            return nil
        }

        return leftParen.positionAfterSkippingLeadingTrivia
    }
}
