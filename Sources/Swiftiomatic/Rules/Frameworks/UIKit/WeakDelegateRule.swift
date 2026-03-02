import SwiftSyntax

struct WeakDelegateRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = WeakDelegateConfiguration()
}

extension WeakDelegateRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension WeakDelegateRule {}

extension WeakDelegateRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      guard node.hasDelegateSuffix,
        node.weakOrUnownedModifier == nil,
        !node.hasComputedBody,
        !node.containsIgnoredAttribute,
        let parent = node.parent,
        Syntax(parent).enclosingClass() != nil
      else {
        return
      }

      violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension Syntax {
  fileprivate func enclosingClass() -> ClassDeclSyntax? {
    if let classExpr = `as`(ClassDeclSyntax.self) {
      return classExpr
    }
    if `as`(DeclSyntax.self) != nil {
      return nil
    }

    return parent?.enclosingClass()
  }
}

extension VariableDeclSyntax {
  fileprivate var hasDelegateSuffix: Bool {
    bindings.allSatisfy { binding in
      guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
        return false
      }

      return pattern.identifier.text.lowercased().hasSuffix("delegate")
    }
  }

  fileprivate var hasComputedBody: Bool {
    bindings.allSatisfy { binding in
      if case .getter = binding.accessorBlock?.accessors {
        return true
      }
      return binding.accessorBlock?.specifiesGetAccessor == true
    }
  }

  fileprivate var containsIgnoredAttribute: Bool {
    let ignoredAttributes: Set = [
      "UIApplicationDelegateAdaptor",
      "NSApplicationDelegateAdaptor",
      "WKExtensionDelegateAdaptor",
    ]

    return attributes.contains { attr in
      guard case .attribute(let customAttr) = attr,
        let typeIdentifier = customAttr.attributeName.as(IdentifierTypeSyntax.self)
      else {
        return false
      }

      return ignoredAttributes.contains(typeIdentifier.name.text)
    }
  }
}
