import SwiftiomaticSyntax

struct PreferSpecializeAttributeRule {
  static let id = "prefer_specialize_attribute"
  static let name = "Prefer @specialize Attribute"
  static let summary =
    "Use '@specialize' instead of the underscored '@_specialize' attribute (Swift 6.3+)"
  static let isCorrectable = true

  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        @specialize(where T == Int)
        func compute<T: Numeric>(_ value: T) -> T { value }
        """
      ),
      Example("func plain<T>(_ x: T) {}"),
      Example("@inlinable func fast() {}"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        ↓@_specialize(where T == Int)
        func compute<T: Numeric>(_ value: T) -> T { value }
        """
      ),
      Example(
        """
        ↓@_specialize(exported: true, where T == String)
        public func format<T>(_ value: T) -> String { "\\(value)" }
        """
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        ↓@_specialize(where T == Int)
        func compute<T: Numeric>(_ value: T) -> T { value }
        """
      ): Example(
        """
        @specialize(where T == Int)
        func compute<T: Numeric>(_ value: T) -> T { value }
        """
      ),
      Example(
        """
        ↓@_specialize(exported: true, where T == String)
        public func format<T>(_ value: T) -> String { "\\(value)" }
        """
      ): Example(
        """
        @specialize(exported: true, where T == String)
        public func format<T>(_ value: T) -> String { "\\(value)" }
        """
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension PreferSpecializeAttributeRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension PreferSpecializeAttributeRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AttributeSyntax) {
      if node.attributeNameText == "_specialize" {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
      guard node.attributeNameText == "_specialize" else { return super.visit(node) }
      guard !isDisabled(atStartPositionOf: node) else { return super.visit(node) }
      guard let oldIdent = node.attributeName.as(IdentifierTypeSyntax.self) else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let newToken = oldIdent.name.with(\.tokenKind, .identifier("specialize"))
      let newName = oldIdent.with(\.name, newToken)
      return super.visit(node.with(\.attributeName, TypeSyntax(newName)))
    }
  }
}
