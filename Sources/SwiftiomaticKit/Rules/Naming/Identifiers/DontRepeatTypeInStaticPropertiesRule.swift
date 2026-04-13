// sm:disable file_header
//
// Adapted from swift-format's DontRepeatTypeInStaticProperties.swift
//
// https://github.com/apple/swift-format
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Foundation
import SwiftiomaticSyntax

struct DontRepeatTypeInStaticPropertiesRule {
  static let id = "dont_repeat_type_in_static_properties"
  static let name = "Don't Repeat Type In Static Properties"
  static let summary =
    "Static properties returning their enclosing type should not repeat the type name in the property name."
  var options = SeverityOption<Self>(.warning)
}

extension DontRepeatTypeInStaticPropertiesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DontRepeatTypeInStaticPropertiesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard node.modifiers.containsStaticOrClass,
        let typeName = enclosingTypeName(of: Syntax(node)),
        let variableTypeName = node.inferredTypeName,
        typeName.hasSuffix(variableTypeName) || variableTypeName == "Self"
      else {
        return
      }

      // Use the final component of a dotted name (e.g. `A.B.C` → `C`)
      let lastTypeName = typeName.components(separatedBy: ".").last!
      let bareTypeName = removingNamespacePrefix(from: lastTypeName)

      for binding in node.bindings {
        guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
          continue
        }
        let varName = identifierPattern.identifier.text
        if varName.lowercased().hasSuffix(bareTypeName.lowercased()),
          varName.count > bareTypeName.count
        {
          violations.append(
            .init(
              position: identifierPattern.positionAfterSkippingLeadingTrivia,
              reason:
                "Remove the suffix '\(bareTypeName)' from the name of the variable '\(varName)'"
            )
          )
        }
      }
    }

    /// Walks up the syntax tree to find the enclosing type name.
    private func enclosingTypeName(of node: Syntax) -> String? {
      var current = node.parent
      while let parent = current {
        switch parent.kind {
        case .actorDecl:
          return parent.as(ActorDeclSyntax.self)?.name.text
        case .classDecl:
          return parent.as(ClassDeclSyntax.self)?.name.text
        case .enumDecl:
          return parent.as(EnumDeclSyntax.self)?.name.text
        case .protocolDecl:
          return parent.as(ProtocolDeclSyntax.self)?.name.text
        case .structDecl:
          return parent.as(StructDeclSyntax.self)?.name.text
        case .extensionDecl:
          if let ext = parent.as(ExtensionDeclSyntax.self) {
            if let simple = ext.extendedType.as(IdentifierTypeSyntax.self) {
              return simple.name.text
            }
            if let member = ext.extendedType.as(MemberTypeSyntax.self) {
              return member.trimmedDescription
            }
          }
          return nil
        default:
          current = parent.parent
        }
      }
      return nil
    }

    /// Strips a possible Objective-C-style namespace prefix (e.g. `UI` from `UIColor` → `Color`).
    ///
    /// If the name has zero or one leading uppercase letters, the entire name is returned.
    private func removingNamespacePrefix(from name: String) -> Substring {
      guard let first = name.first, first.isUppercase else { return name[...] }

      for index in name.indices.dropLast() {
        let nextIndex = name.index(after: index)
        if name[index].isUppercase && !name[nextIndex].isUppercase {
          return name[index...]
        }
      }
      return name[...]
    }
  }
}

extension VariableDeclSyntax {
  /// Infers the type name from a type annotation or initializer expression.
  fileprivate var inferredTypeName: String? {
    if let typeAnnotation = bindings.first?.typeAnnotation {
      return typeAnnotation.type.trimmedDescription
    }
    if let calledExpr = bindings.first?.initializer?.value.as(FunctionCallExprSyntax.self)?
      .calledExpression
    {
      // Handle `Foo.init()` — use the base type
      if let memberAccess = calledExpr.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.tokenKind == .keyword(.`init`)
      {
        return memberAccess.base?.trimmedDescription
      }
      return calledExpr.trimmedDescription
    }
    return nil
  }
}
