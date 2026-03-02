import SwiftSyntax

struct LowerACLThanParentRule {
    var options = SeverityConfiguration<Self>(.warning)

    static let configuration = LowerACLThanParentConfiguration()
}

extension LowerACLThanParentRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension LowerACLThanParentRule {}

extension LowerACLThanParentRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: DeclModifierSyntax) {
            if node.isHigherACLThanParent {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
            guard node.isHigherACLThanParent else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let newNode: DeclModifierSyntax
            if node.name.tokenKind == .keyword(.open) {
                newNode = DeclModifierSyntax(
                    leadingTrivia: node.leadingTrivia,
                    name: .keyword(.public),
                    trailingTrivia: .space,
                )
            } else {
                newNode = DeclModifierSyntax(
                    leadingTrivia: node.leadingTrivia,
                    name: .identifier(""),
                )
            }

            return super.visit(newNode)
        }
    }
}

extension DeclModifierSyntax {
    fileprivate var isHigherACLThanParent: Bool {
        guard let nearestNominalParent = parent?.nearestNominalParent() else {
            return false
        }

        switch name.tokenKind {
            case .keyword(.internal)
            where nearestNominalParent.modifiers?.containsPrivateOrFileprivate() == true:
                return true
            case .keyword(.internal)
            where nearestNominalParent.modifiers?.accessLevelModifier == nil:
                guard
                    let nominalExtension =
                    nearestNominalParent
                        .nearestNominalExtensionDeclParent()
                else {
                    return false
                }
                return nominalExtension.modifiers?.containsPrivateOrFileprivate() == true
            case .keyword(.public)
            where nearestNominalParent.modifiers?.containsPrivateOrFileprivate() == true
            || nearestNominalParent.modifiers?.contains(keyword: .internal) == true:
                return true
            case .keyword(.public) where nearestNominalParent.modifiers?.accessLevelModifier == nil:
                guard
                    let nominalExtension =
                    nearestNominalParent
                        .nearestNominalExtensionDeclParent()
                else {
                    return true
                }
                return nominalExtension.modifiers?.contains(keyword: .public) == false
            case .keyword(.open)
            where nearestNominalParent.modifiers?.contains(keyword: .open) == false:
                return true
            default:
                return false
        }
    }
}

extension SyntaxProtocol {
    fileprivate func nearestNominalParent() -> Syntax? {
        guard let parent else {
            return nil
        }

        return parent.isNominalTypeDecl ? parent : parent.nearestNominalParent()
    }

    fileprivate func nearestNominalExtensionDeclParent() -> Syntax? {
        guard let parent, !parent.isNominalTypeDecl else {
            return nil
        }

        return parent.isExtensionDecl ? parent : parent.nearestNominalExtensionDeclParent()
    }
}

extension Syntax {
    fileprivate var isNominalTypeDecl: Bool {
        `is`(StructDeclSyntax.self) || `is`(ClassDeclSyntax.self) || `is`(ActorDeclSyntax.self)
            || `is`(EnumDeclSyntax.self)
    }

    fileprivate var isExtensionDecl: Bool {
        `is`(ExtensionDeclSyntax.self)
    }

    fileprivate var modifiers: DeclModifierListSyntax? {
        asProtocol((any WithModifiersSyntax).self)?.modifiers
    }
}
