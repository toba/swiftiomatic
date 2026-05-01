//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Static properties of a type that return that type should not include a reference to their type.
///
/// "Reference to their type" means that the property name includes part, or all, of the type. If
/// the type contains a namespace (i.e. `UIColor` ) the namespace is ignored;
/// `public class var redColor: UIColor` would trigger this rule.
///
/// Lint: Static properties of a type that return that type will yield a lint error.
final class DropTypeInStaticProperty: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .types }

    /// Visits the static/class properties and diagnoses any where the name has the containing type
    /// name (excluding possible namespace prefixes, like `NS` or `UI` ) as a suffix.
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifiers.contains(anyOf: [.class, .static]),
              let typeName = Syntax(node).containingDeclName,
              let variableTypeName = node.typeName,
              typeName.hasSuffix(variableTypeName) || variableTypeName == "Self" else {
            return .visitChildren
        }

        // the final component of the top type `A.B.C.D` is what we want `D` .
        let lastTypeName = typeName.components(separatedBy: ".").last!
        let bareTypeName = removingPossibleNamespacePrefix(from: lastTypeName)

        for binding in node.bindings {
            guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }

            let varName = identifierPattern.identifier.text

            if varName.hasSuffix(bareTypeName) {
                diagnose(
                    .removeTypeFromName(name: varName, type: bareTypeName), on: identifierPattern)
            }
        }

        return .visitChildren
    }

    /// Returns the portion of the given string that excludes a possible Objective-C-style
    /// capitalized namespace prefix (a leading sequence of more than one uppercase letter).
    ///
    /// If the name has zero or one leading uppercase letters, the entire name is returned.
    private func removingPossibleNamespacePrefix(from name: String) -> Substring {
        guard let first = name.first, first.isUppercase else { return name[...] }

        for index in name.indices.dropLast() {
            let nextIndex = name.index(after: index)
            if name[index].isUppercase, !name[nextIndex].isUppercase { return name[index...] }
        }

        return name[...]
    }
}

fileprivate extension Finding.Message {
    static func removeTypeFromName(name: String, type: Substring) -> Finding.Message {
        "remove the suffix '\(type)' from the name of the variable '\(name)'"
    }
}

fileprivate extension Syntax {
    /// Returns the name of the immediately enclosing type of this decl if there is one, otherwise
    /// nil.
    var containingDeclName: String? {
        switch Syntax(self).as(SyntaxEnum.self) {
            case let .actorDecl(node): return node.name.text
            case let .classDecl(node): return node.name.text
            case let .enumDecl(node): return node.name.text
            case let .protocolDecl(node): return node.name.text
            case let .structDecl(node): return node.name.text
            case let .extensionDecl(node):
                switch Syntax(node.extendedType).as(SyntaxEnum.self) {
                    case let .identifierType(simpleType): return simpleType.name.text
                    case let .memberType(memberType):
                        return memberType.description.trimmingCharacters(
                            in: .whitespacesAndNewlines)
                    default: return nil
                }
            default:
                if let parent = self.parent { return parent.containingDeclName }

                return nil
        }
    }
}

fileprivate extension VariableDeclSyntax {
    var typeName: String? {
        if let typeAnnotation = bindings.first?.typeAnnotation {
            typeAnnotation.type.description
        } else if let initializerCalledExpression = bindings.first?.initializer?.value.as(
            FunctionCallExprSyntax.self)?
            .calledExpression
        {
            if let memberAccessExprSyntax = initializerCalledExpression.as(
                MemberAccessExprSyntax.self),
               memberAccessExprSyntax.declName.baseName.tokenKind == .keyword(.`init`)
            {
                memberAccessExprSyntax.base?.description
            } else {
                initializerCalledExpression.description
            }
        } else {
            nil
        }
    }
}
