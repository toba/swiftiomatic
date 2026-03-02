import SwiftSyntax

struct ValidIBInspectableRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ValidIBInspectableConfiguration()

  fileprivate static let supportedTypes: Set<String> = {
    // "You can add the IBInspectable attribute to any property in a class declaration,
    // class extension, or category of type: boolean, integer or floating point number, string,
    // localized string, rectangle, point, size, color, range, and nil."
    //
    // from http://help.apple.com/xcode/mac/8.0/#/devf60c1c514

    let referenceTypes = [
      "String",
      "NSString",
      "UIColor",
      "NSColor",
      "UIImage",
      "NSImage",
    ]

    let types = [
      "CGFloat",
      "Float",
      "Double",
      "Bool",
      "CGPoint",
      "NSPoint",
      "CGSize",
      "NSSize",
      "CGRect",
      "NSRect",
    ]

    let intTypes: [String] = ["", "8", "16", "32", "64"].flatMap { size in
      ["U", ""].map { (sign: String) -> String in
        "\(sign)Int\(size)"
      }
    }

    let expandToIncludeOptionals: (String) -> [String] = { [$0, $0 + "!", $0 + "?"] }

    // It seems that only reference types can be used as ImplicitlyUnwrappedOptional or Optional
    return Set(referenceTypes.flatMap(expandToIncludeOptionals) + types + intTypes)
  }()
}

extension ValidIBInspectableRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ValidIBInspectableRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [FunctionDeclSyntax.self]
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      if node.isInstanceVariable, node.isIBInspectable, node.hasViolation {
        violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension VariableDeclSyntax {
  fileprivate var isIBInspectable: Bool {
    attributes.contains(attributeNamed: "IBInspectable")
  }

  fileprivate var hasViolation: Bool {
    isReadOnlyProperty || !isSupportedType
  }

  fileprivate var isReadOnlyProperty: Bool {
    if bindingSpecifier.tokenKind == .keyword(.let) {
      return true
    }

    let computedProperty = bindings.contains { binding in
      binding.accessorBlock != nil
    }

    if !computedProperty {
      return false
    }

    return bindings.allSatisfy { binding in
      guard let accessorBlock = binding.accessorBlock else {
        return true
      }

      // if it has a `get`, it needs to have a `set`, otherwise it's readonly
      if accessorBlock.getAccessor != nil {
        return accessorBlock.setAccessor == nil
      }

      return false
    }
  }

  fileprivate var isSupportedType: Bool {
    bindings.allSatisfy { binding in
      guard let type = binding.typeAnnotation else {
        return false
      }

      return ValidIBInspectableRule.supportedTypes.contains(type.type.trimmedDescription)
    }
  }
}
