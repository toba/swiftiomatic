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
///
/// Format: The redundant `@objc` attribute is removed.
@_spi(Rules)
public final class RedundantObjc: SyntaxFormatRule {
  public override class var group: ConfigGroup? { .removeRedundant }

  /// Attributes that imply `@objc`.
  private static let implyingAttributes: Set<String> = [
    "IBAction",
    "IBOutlet",
    "IBDesignable",
    "IBInspectable",
    "NSManaged",
    "GKInspectable",
  ]

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantObjc(from: node))
  }

  public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantObjc(from: node))
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(ClassDeclSyntax.self)
    return DeclSyntax(removeRedundantObjc(from: visited))
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(StructDeclSyntax.self)
    return DeclSyntax(removeRedundantObjc(from: visited))
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let visited = super.visit(node).cast(EnumDeclSyntax.self)
    return DeclSyntax(removeRedundantObjc(from: visited))
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantObjc(from: node))
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    DeclSyntax(removeRedundantObjc(from: node))
  }

  private func removeRedundantObjc<Decl: DeclSyntaxProtocol & WithAttributesSyntax>(
    from decl: Decl
  ) -> Decl {
    guard let objcAttr = decl.attributes.attribute(named: "objc") else {
      return decl
    }
    // `@objc(selector:)` provides an explicit name — not redundant.
    guard objcAttr.arguments == nil else {
      return decl
    }
    // Must have at least one attribute that implies `@objc`.
    guard decl.attributes.contains(where: { element in
      guard case .attribute(let attr) = element,
        let name = attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text
      else { return false }
      return Self.implyingAttributes.contains(name)
    }) else {
      return decl
    }

    diagnose(.removeRedundantObjc, on: objcAttr)

    var result = decl
    result.attributes = decl.attributes.removing(named: "objc")
    return result
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantObjc: Finding.Message =
    "remove redundant '@objc'; it is implied by another attribute"
}
