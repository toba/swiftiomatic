import SwiftiomaticSyntax

struct RedundantSetAccessControlRule {
  static let id = "redundant_set_access_control"
  static let name = "Redundant Access Control for Setter"
  static let summary =
    "Property setter access level shouldn't be explicit if it's the same as the variable access level"
  static var nonTriggeringExamples: [Example] {
    [
      Example("private(set) public var foo: Int"),
      Example("public let foo: Int"),
      Example("public var foo: Int"),
      Example("var foo: Int"),
      Example(
        """
        private final class A {
          private(set) var value: Int
        }
        """,
      ),
      Example(
        """
        fileprivate class A {
          public fileprivate(set) var value: Int
        }
        """, isExcludedFromDocumentation: true,
      ),
      Example(
        """
        extension Color {
            public internal(set) static var someColor = Color.anotherColor
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓private(set) private var foo: Int"),
      Example("↓fileprivate(set) fileprivate var foo: Int"),
      Example("↓internal(set) internal var foo: Int"),
      Example("↓public(set) public var foo: Int"),
      Example(
        """
        open class Foo {
          ↓open(set) open var bar: Int
        }
        """,
      ),
      Example(
        """
        class A {
          ↓internal(set) var value: Int
        }
        """,
      ),
      Example(
        """
        internal class A {
          ↓internal(set) var value: Int
        }
        """,
      ),
      Example(
        """
        fileprivate class A {
          ↓fileprivate(set) var value: Int
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension RedundantSetAccessControlRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantSetAccessControlRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [FunctionDeclSyntax.self]
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      let modifiers = node.modifiers
      guard let setAccessor = modifiers.setAccessor else {
        return
      }

      let uniqueModifiers = Set(modifiers.map(\.name.tokenKind))
      if uniqueModifiers.count != modifiers.count {
        violations.append(modifiers.positionAfterSkippingLeadingTrivia)
        return
      }

      if setAccessor.name.tokenKind == .keyword(.fileprivate),
        modifiers.getAccessor == nil,
        let closestDeclModifiers = node.closestDecl()?.modifiers
      {
        let closestDeclIsFilePrivate = closestDeclModifiers.contains {
          $0.name.tokenKind == .keyword(.fileprivate)
        }

        if closestDeclIsFilePrivate {
          violations.append(modifiers.positionAfterSkippingLeadingTrivia)
          return
        }
      }

      if setAccessor.name.tokenKind == .keyword(.internal),
        modifiers.getAccessor == nil,
        let closesDecl = node.closestDecl(),
        let closestDeclModifiers = closesDecl.modifiers
      {
        let closestDeclIsInternal =
          closestDeclModifiers.isEmpty
          || closestDeclModifiers.contains {
            $0.name.tokenKind == .keyword(.internal)
          }

        if closestDeclIsInternal {
          violations.append(modifiers.positionAfterSkippingLeadingTrivia)
          return
        }
      }
    }
  }
}

extension SyntaxProtocol {
  fileprivate func closestDecl() -> DeclSyntax? {
    if let decl = parent?.as(DeclSyntax.self) {
      return decl
    }

    return parent?.closestDecl()
  }
}

extension DeclSyntax {
  fileprivate var modifiers: DeclModifierListSyntax? {
    asProtocol((any WithModifiersSyntax).self)?.modifiers
  }
}

extension DeclModifierListSyntax {
  fileprivate var setAccessor: DeclModifierSyntax? {
    first { $0.detail?.detail.tokenKind == .identifier("set") }
  }

  fileprivate var getAccessor: DeclModifierSyntax? {
    first { $0.detail == nil }
  }
}
