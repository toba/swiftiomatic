import SwiftSyntax

struct NonOverridableClassDeclarationRule {
    var options = NonOverridableClassDeclarationOptions()

    static let configuration = NonOverridableClassDeclarationConfiguration()
}

extension NonOverridableClassDeclarationRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension NonOverridableClassDeclarationRule {}

extension NonOverridableClassDeclarationRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        private var finalClassScope = Stack<Bool>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [ProtocolDeclSyntax.self]
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            finalClassScope.push(node.modifiers.contains(keyword: .final))
            return .visitChildren
        }

        override func visitPost(_: ClassDeclSyntax) {
            _ = finalClassScope.pop()
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            checkViolations(for: node.modifiers, types: "methods")
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            checkViolations(for: node.modifiers, types: "properties")
        }

        private func checkViolations(for modifiers: DeclModifierListSyntax, types: String) {
            guard !modifiers.contains(keyword: .final),
                  let classKeyword = modifiers.first(where: { $0.name.text == "class" }),
                  case let inFinalClass = finalClassScope.peek() == true,
                  inFinalClass || modifiers.contains(keyword: .private)
            else {
                return
            }
            violations.append(
                .init(
                    position: classKeyword.positionAfterSkippingLeadingTrivia,
                    reason: inFinalClass
                        ? "Class \(types) in final classes should themselves be final"
                        : "Private class methods and properties should be declared final",
                    severity: configuration.severity,
                    correction: .init(
                        start: classKeyword.positionAfterSkippingLeadingTrivia,
                        end: classKeyword.endPositionBeforeTrailingTrivia,
                        replacement: configuration.finalClassModifier.rawValue,
                    ),
                ),
            )
        }
    }
}
