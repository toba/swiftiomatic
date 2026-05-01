import SwiftSyntax

/// Protocols whose name ends in `Delegate` should be class-constrained.
///
/// Delegate properties are typically declared `weak` to avoid retain cycles. The `weak` modifier is
/// only valid on class-bound references, so a delegate protocol must inherit from `AnyObject` (or
/// `NSObjectProtocol` , `Actor` , another `*Delegate` protocol) — otherwise it cannot be held
/// weakly.
///
/// Lint: A protocol whose name ends in `Delegate` and is not class-constrained yields a warning.
final class RequireAnyObjectOnDelegate: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .memory }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.name.text.hasSuffix("Delegate"),
              !node.hasObjCAttribute,
              !node.isClassRestricted,
              !node.inheritsFromObjectOrDelegate else {
            return .visitChildren
        }

        diagnose(.requireAnyObjectOnDelegate(name: node.name.text), on: node.protocolKeyword)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func requireAnyObjectOnDelegate(name: String) -> Finding.Message {
        "make '\(name)' class-constrained (e.g. ': AnyObject') so it can be referenced weakly"
    }
}

fileprivate extension ProtocolDeclSyntax {
    var hasObjCAttribute: Bool {
        attributes.contains { element in
            if let attr = element.as(AttributeSyntax.self),
               let name = attr.attributeName.as(IdentifierTypeSyntax.self)
            {
                name.name.text == "objc"
            } else {
                false
            }
        }
    }

    var isClassRestricted: Bool {
        inheritanceClause?.inheritedTypes.contains {
            $0.type.is(ClassRestrictionTypeSyntax.self)
        } ?? false
    }

    var inheritsFromObjectOrDelegate: Bool {
        if inheritanceClause?.inheritedTypes.contains(where: { $0.type.isObjectOrDelegate }) == true
        {
            return true
        }
        guard let requirements = genericWhereClause?.requirements else { return false }

        return requirements.contains { requirement in
            guard let conformance = requirement.requirement.as(ConformanceRequirementSyntax.self),
                  let leftID = conformance.leftType.as(IdentifierTypeSyntax.self),
                  leftID.name.text == "Self" else { return false }
            return conformance.rightType.isObjectOrDelegate
        }
    }
}

fileprivate extension TypeSyntax {
    var isObjectOrDelegate: Bool {
        if let name = self.as(IdentifierTypeSyntax.self)?.name.text {
            let objectTypes: Set<String> = ["AnyObject", "NSObjectProtocol", "Actor"]
            return objectTypes.contains(name) || name.hasSuffix("Delegate")
        }
        if let composition = self.as(CompositionTypeSyntax.self) {
            return composition.elements.contains { $0.type.isObjectOrDelegate }
        }
        return false
    }
}
