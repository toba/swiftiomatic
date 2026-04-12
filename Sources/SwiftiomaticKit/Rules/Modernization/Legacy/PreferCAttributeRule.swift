import SwiftiomaticSyntax

struct PreferCAttributeRule {
  static let id = "prefer_c_attribute"
  static let name = "Prefer @c Attribute"
  static let summary = "Use '@c' instead of the deprecated '@_cdecl' attribute (Swift 6.3+)"
  static let isCorrectable = true

  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        @c("myFunction")
        func myFunction() {}
        """
      ),
      Example("func plainFunction() {}"),
      Example("@inline(__always) func fast() {}"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        ↓@_cdecl("myFunction")
        func myFunction() {}
        """
      ),
      Example(
        """
        ↓@_cdecl("process")
        public func process(_ x: Int) -> Int { x }
        """
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        ↓@_cdecl("myFunction")
        func myFunction() {}
        """
      ): Example(
        """
        @c("myFunction")
        func myFunction() {}
        """
      ),
      Example(
        """
        ↓@_cdecl("process")
        public func process(_ x: Int) -> Int { x }
        """
      ): Example(
        """
        @c("process")
        public func process(_ x: Int) -> Int { x }
        """
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension PreferCAttributeRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension PreferCAttributeRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AttributeSyntax) {
      if node.attributeNameText == "_cdecl" {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
      guard node.attributeNameText == "_cdecl" else { return super.visit(node) }
      guard !isDisabled(atStartPositionOf: node) else { return super.visit(node) }
      guard let oldIdent = node.attributeName.as(IdentifierTypeSyntax.self) else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newToken = oldIdent.name.with(\.tokenKind, .identifier("c"))
      let newName = oldIdent.with(\.name, newToken)
      return super.visit(node.with(\.attributeName, TypeSyntax(newName)))
    }
  }
}
