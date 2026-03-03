import SwiftSyntax

struct RedundantVoidReturnRule {
    static let id = "redundant_void_return"
    static let name = "Redundant Void Return"
    static let summary = "Returning Void in a function declaration is redundant"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("func foo() {}"),
            Example("func foo() -> Int {}"),
            Example("func foo() -> Int -> Void {}"),
            Example("func foo() -> VoidResponse"),
            Example("let foo: (Int) -> Void"),
            Example("func foo() -> Int -> () {}"),
            Example("let foo: (Int) -> ()"),
            Example("func foo() -> ()?"),
            Example("func foo() -> ()!"),
            Example("func foo() -> Void?"),
            Example("func foo() -> Void!"),
            Example(
                """
                struct A {
                    subscript(key: String) {
                        print(key)
                    }
                }
                """,
            ),
            Example(
                """
                doSomething { arg -> Void in
                    print(arg)
                }
                """, configuration: ["include_closures": false],
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("func foo()↓ -> Void {}"),
            Example(
                """
                protocol Foo {
                  func foo()↓ -> Void
                }
                """,
            ),
            Example("func foo()↓ -> () {}"),
            Example("func foo()↓ -> ( ) {}"),
            Example(
                """
                protocol Foo {
                  func foo()↓ -> ()
                }
                """,
            ),
            Example(
                """
                doSomething { arg↓ -> () in
                    print(arg)
                }
                """,
            ),
            Example(
                """
                doSomething { arg↓ -> Void in
                    print(arg)
                }
                """,
            ),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example("func foo()↓ -> Void {}"): Example("func foo() {}"),
            Example("protocol Foo {\n func foo()↓ -> Void\n}"): Example(
                "protocol Foo {\n func foo()\n}",
            ),
            Example("func foo()↓ -> () {}"): Example("func foo() {}"),
            Example("protocol Foo {\n func foo()↓ -> ()\n}"): Example(
                "protocol Foo {\n func foo()\n}",
            ),
            Example("protocol Foo {\n    #if true\n    func foo()↓ -> Void\n    #endif\n}"):
                Example("protocol Foo {\n    #if true\n    func foo()\n    #endif\n}"),
        ]
    }

    var options = RedundantVoidReturnOptions()
}

extension RedundantVoidReturnRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension RedundantVoidReturnRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: ReturnClauseSyntax) {
            if !configuration.includeClosures,
               node.parent?.is(ClosureSignatureSyntax.self) == true
            {
                return
            }

            if node.containsRedundantVoidViolation,
               let tokenBeforeOutput = node.previousToken(viewMode: .sourceAccurate)
            {
                violations.append(tokenBeforeOutput.endPositionBeforeTrailingTrivia)
            }
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
            guard configuration.includeClosures,
                  let output = node.returnClause,
                  output.previousToken(viewMode: .sourceAccurate) != nil,
                  output.containsRedundantVoidViolation
            else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            return super.visit(node.with(\.returnClause, nil).removingTrailingSpaceIfNeeded())
        }

        override func visit(_ node: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
            guard let output = node.returnClause,
                  output.previousToken(viewMode: .sourceAccurate) != nil,
                  output.containsRedundantVoidViolation
            else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            return super.visit(node.with(\.returnClause, nil).removingTrailingSpaceIfNeeded())
        }
    }
}

extension ReturnClauseSyntax {
    fileprivate var containsRedundantVoidViolation: Bool {
        if parent?.is(FunctionTypeSyntax.self) == true {
            return false
        }
        if let simpleReturnType = type.as(IdentifierTypeSyntax.self) {
            return simpleReturnType.typeName == "Void"
        }
        if let tupleReturnType = type.as(TupleTypeSyntax.self) {
            return tupleReturnType.elements.isEmpty
        }
        return false
    }
}

extension SyntaxProtocol {
    /// `withOutput(nil)` adds a `.spaces(1)` trailing trivia, but we don't always want it.
    fileprivate func removingTrailingSpaceIfNeeded() -> Self {
        guard
            let nextToken = nextToken(viewMode: .sourceAccurate),
            nextToken.leadingTrivia.containsNewlines()
        else {
            return self
        }

        return with(
            \.trailingTrivia,
            Trivia(pieces: trailingTrivia.dropFirst()),
        )
    }
}
