import SwiftSyntax

struct NoExplicitOwnershipRule {
    var options = SeverityConfiguration<Self>(.warning)

    static let configuration = NoExplicitOwnershipConfiguration()
}

extension NoExplicitOwnershipRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension NoExplicitOwnershipRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: FunctionParameterSyntax) {
            checkOwnershipSpecifier(node.type)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            for modifier in node.modifiers {
                if modifier.name.tokenKind == .keyword(.borrowing)
                    || modifier.name.tokenKind == .keyword(.consuming)
                {
                    violations.append(modifier.positionAfterSkippingLeadingTrivia)
                }
            }
        }

        private func checkOwnershipSpecifier(_ type: TypeSyntax) {
            if let attributed = type.as(AttributedTypeSyntax.self) {
                for specifier in attributed.specifiers {
                    if case let .simpleTypeSpecifier(simple) = specifier,
                       simple.specifier.tokenKind == .keyword(.borrowing)
                       || simple.specifier.tokenKind == .keyword(.consuming)
                    {
                        violations.append(simple.positionAfterSkippingLeadingTrivia)
                    }
                }
            }
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: AttributedTypeSyntax) -> TypeSyntax {
            var modified = false
            let newSpecifiers = node.specifiers.filter { specifier in
                if case let .simpleTypeSpecifier(simple) = specifier,
                   simple.specifier.tokenKind == .keyword(.borrowing)
                   || simple.specifier.tokenKind == .keyword(.consuming)
                {
                    modified = true
                    return false
                }
                return true
            }

            guard modified else { return super.visit(node) }
            numberOfCorrections += 1

            if newSpecifiers.isEmpty, node.attributes.isEmpty {
                return super.visit(node).with(\.leadingTrivia, node.leadingTrivia)
            }
            let newNode = node.with(\.specifiers, newSpecifiers)
            return super.visit(newNode)
        }
    }
}
