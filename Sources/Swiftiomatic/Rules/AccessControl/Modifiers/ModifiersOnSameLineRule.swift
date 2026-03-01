import SwiftSyntax

struct ModifiersOnSameLineRule {
    var options = SeverityConfiguration<Self>(.warning)

    static let configuration = ModifiersOnSameLineConfiguration()

    static let description = RuleDescription(
        identifier: "modifiers_on_same_line",
        name: "Modifiers on Same Line",
        description: "Modifiers should be on the same line as the declaration keyword",
        scope: .format,
        nonTriggeringExamples: [
            Example("public var foo: Foo"),
            Example("@MainActor public private(set) var foo: Foo"),
            Example("nonisolated func bar() {}"),
        ],
        triggeringExamples: [
            Example(
                """
                ↓public
                private(set)
                var foo: Foo
                """,
            ),
            Example(
                """
                ↓nonisolated
                func bar() {}
                """,
            ),
        ],
        corrections: [
            Example("↓public\nvar foo: Foo"): Example("public var foo: Foo"),
            Example("↓nonisolated\nfunc bar() {}"): Example("nonisolated func bar() {}"),
        ],
    )
}

extension ModifiersOnSameLineRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension ModifiersOnSameLineRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: VariableDeclSyntax) {
            checkModifiers(node.modifiers, keyword: node.bindingSpecifier)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            checkModifiers(node.modifiers, keyword: node.funcKeyword)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            checkModifiers(node.modifiers, keyword: node.classKeyword)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            checkModifiers(node.modifiers, keyword: node.structKeyword)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            checkModifiers(node.modifiers, keyword: node.enumKeyword)
        }

        private func checkModifiers(_ modifiers: DeclModifierListSyntax, keyword: TokenSyntax) {
            guard let firstModifier = modifiers.first else { return }

            // Check if any modifier or the keyword is on a different line
            let allTokens: [TokenSyntax] = modifiers.map(\.name) + [keyword]
            for i in 1 ..< allTokens.count {
                if allTokens[i].leadingTrivia.containsNewlines() {
                    violations.append(firstModifier.positionAfterSkippingLeadingTrivia)
                    return
                }
            }
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
            // Remove newlines from leading trivia of modifiers (except the first one)
            guard node.leadingTrivia.containsNewlines() else { return super.visit(node) }

            // Only rewrite if this is not the first modifier
            guard let parent = node.parent,
                  let modifierList = parent.as(DeclModifierListSyntax.self),
                  modifierList.first?.id != node.id
            else {
                return super.visit(node)
            }

            numberOfCorrections += 1
            let newTrivia = Trivia.space
            return super.visit(node.with(\.leadingTrivia, newTrivia))
        }
    }
}
