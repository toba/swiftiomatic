import Foundation
import SwiftSyntax

private let attributeNamesImplyingObjc: Set<String> = [
  "IBAction", "IBOutlet", "IBInspectable", "GKInspectable", "IBDesignable", "NSManaged",
]

struct RedundantObjcAttributeRule: SwiftSyntaxRule, SubstitutionCorrectableRule {
    static let id = "redundant_objc_attribute"
    static let name = "Redundant @objc Attribute"
    static let summary = "Objective-C attribute (@objc) is redundant in declaration"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        RedundantObjcAttributeRuleExamples.nonTriggeringExamples
    }
    static var triggeringExamples: [Example] {
        RedundantObjcAttributeRuleExamples.triggeringExamples
    }
    static var corrections: [Example: Example] {
        RedundantObjcAttributeRuleExamples.corrections
    }
  var options = SeverityConfiguration<Self>(.warning)

  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    final class Visitor: ViolationCollectingVisitor<OptionsType> {
      override func visitPost(_ node: AttributeListSyntax) {
        if let objcAttribute = node.violatingObjCAttribute {
          violations.append(objcAttribute.positionAfterSkippingLeadingTrivia)
        }
      }
    }
    return Visitor(configuration: options, file: file)
  }

  func violationRanges(in file: SwiftSource) -> [Range<String.Index>] {
    makeVisitor(file: file)
      .walk(tree: file.syntaxTree, handler: \.violations)
      .compactMap { violation in
        let end = AbsolutePosition(
          utf8Offset: violation.position.utf8Offset
            + "@objc"
            .count)
        return file.stringView.stringRange(start: violation.position, end: end)
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

extension RedundantObjcAttributeRule {
  func substitution(for violationRange: Range<String.Index>, in file: SwiftSource)
    -> (Range<String.Index>, String)?
  {
    let contents = file.contents
    var endIndex = violationRange.upperBound
    while endIndex < contents.endIndex,
      contents[endIndex].isWhitespace || contents[endIndex].isNewline
    {
      endIndex = contents.index(after: endIndex)
    }
    return (violationRange.lowerBound..<endIndex, "")
  }
}
