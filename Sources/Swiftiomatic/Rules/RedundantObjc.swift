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

/// Remove `@objc` when it is already implied by another attribute.
///
/// The `@objc` attribute is automatically implied by `@IBAction`, `@IBOutlet`, `@IBDesignable`,
/// `@IBInspectable`, `@NSManaged`, and `@GKInspectable`. Writing `@objc` alongside any of these
/// is redundant.
///
/// This rule does NOT flag `@objc` when it specifies an explicit Objective-C name
/// (e.g. `@objc(mySelector:)`), since that provides information beyond just marking the
/// declaration as ObjC-visible.
///
/// Lint: If a redundant `@objc` is found, a lint warning is raised.
@_spi(Rules)
public final class RedundantObjc: SyntaxLintRule {

  /// Attributes that imply `@objc`.
  private static let implyingAttributes: Set<String> = [
    "IBAction",
    "IBOutlet",
    "IBDesignable",
    "IBInspectable",
    "NSManaged",
    "GKInspectable",
  ]

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    checkAttributes(node.attributes)
    return .visitChildren
  }

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    checkAttributes(node.attributes)
    return .visitChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    checkAttributes(node.attributes)
    return .visitChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    checkAttributes(node.attributes)
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    checkAttributes(node.attributes)
    return .visitChildren
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
    checkAttributes(node.attributes)
    return .visitChildren
  }

  public override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    checkAttributes(node.attributes)
    return .visitChildren
  }

  private func checkAttributes(_ attributes: AttributeListSyntax) {
    var objcAttribute: AttributeSyntax?
    var hasImplyingAttribute = false

    for element in attributes {
      guard case .attribute(let attr) = element else { continue }

      if let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text {
        if name == "objc" {
          // Skip `@objc(name:)` — the explicit name is not redundant.
          if attr.arguments != nil {
            return
          }
          objcAttribute = attr
        } else if Self.implyingAttributes.contains(name) {
          hasImplyingAttribute = true
        }
      }
    }

    if let objcAttr = objcAttribute, hasImplyingAttribute {
      diagnose(.removeRedundantObjc, on: objcAttr)
    }
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantObjc: Finding.Message =
    "remove redundant '@objc'; it is implied by another attribute"
}
