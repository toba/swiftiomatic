import Foundation
import SwiftSyntax

private let attributeNamesImplyingObjc: Set<String> = [
  "IBAction", "IBOutlet", "IBInspectable", "GKInspectable", "IBDesignable", "NSManaged",
]

struct RedundantObjcAttributeRule {
    static let id = "redundant_objc_attribute"
    static let name = "Redundant @objc Attribute"
    static let summary = "Objective-C attribute (@objc) is redundant in declaration"
    static let isCorrectable = true
  var options = SeverityOption<Self>(.warning)
}

extension RedundantObjcAttributeRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AttributeListSyntax) {
      guard let objcAttribute = node.violatingObjCAttribute else { return }

      let start = objcAttribute.positionAfterSkippingLeadingTrivia
      // Extend removal through trailing whitespace/newlines to the next meaningful token
      let end: AbsolutePosition
      if let nextToken = objcAttribute.lastToken(viewMode: .sourceAccurate)?
        .nextToken(viewMode: .sourceAccurate)
      {
        end = nextToken.positionAfterSkippingLeadingTrivia
      } else {
        end = objcAttribute.endPosition
      }

      let correction = SyntaxViolation.Correction(
        start: start,
        end: end,
        replacement: "",
      )
      violations.append(
        SyntaxViolation(
          position: start,
          severity: configuration.severity,
          correction: correction,
        ),
      )
    }
  }
}

extension AttributeListSyntax {
  fileprivate var objCAttribute: AttributeSyntax? {
    lazy
      .compactMap { $0.as(AttributeSyntax.self) }
      .first { $0.attributeNameText == "objc" && $0.arguments == nil }
  }

  fileprivate var hasAttributeImplyingObjC: Bool {
    contains { element in
      guard let attributeName = element.as(AttributeSyntax.self)?.attributeNameText else {
        return false
      }

      return attributeNamesImplyingObjc.contains(attributeName)
    }
  }
}

extension Syntax {
  fileprivate var isFunctionOrStoredProperty: Bool {
    if `is`(FunctionDeclSyntax.self) {
      return true
    }
    if let variableDecl = `as`(VariableDeclSyntax.self),
      variableDecl.bindings.allSatisfy({ $0.accessorBlock == nil })
    {
      return true
    }
    return false
  }

  fileprivate var functionOrVariableModifiers: DeclModifierListSyntax? {
    if let functionDecl = `as`(FunctionDeclSyntax.self) {
      return functionDecl.modifiers
    }
    if let variableDecl = `as`(VariableDeclSyntax.self) {
      return variableDecl.modifiers
    }
    return nil
  }
}

extension AttributeListSyntax {
  fileprivate var violatingObjCAttribute: AttributeSyntax? {
    guard let objcAttribute = objCAttribute else {
      return nil
    }

    if hasAttributeImplyingObjC, parent?.is(ExtensionDeclSyntax.self) != true {
      return objcAttribute
    }
    if parent?.is(EnumDeclSyntax.self) == true {
      return nil
    }
    if parent?.isFunctionOrStoredProperty == true,
      let parentClassDecl = parent?.parent?.parent?.parent?.parent?.as(ClassDeclSyntax.self),
      parentClassDecl.attributes.contains(attributeNamed: "objcMembers")
    {
      return parent?.functionOrVariableModifiers?.containsPrivateOrFileprivate() == true
        ? nil : objcAttribute
    }
    if let parentExtensionDecl = parent?.parent?.parent?.parent?.parent?.as(
      ExtensionDeclSyntax.self,
    ),
      parentExtensionDecl.attributes.objCAttribute != nil
    {
      return objcAttribute
    }
    return nil
  }
}
