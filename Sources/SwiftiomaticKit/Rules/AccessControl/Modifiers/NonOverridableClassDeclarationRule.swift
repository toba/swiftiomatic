import SwiftiomaticSyntax

struct NonOverridableClassDeclarationRule {
  static let id = "non_overridable_class_declaration"
  static let name = "Class Declaration in Final Class"
  static let summary = "Use `static` or `final` instead of `class` for non-overridable members"
  static let isCorrectable = true
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        final class C {
            final class var b: Bool { true }
            final class func f() {}
        }
        """,
      ),
      Example(
        """
        class C {
            final class var b: Bool { true }
            final class func f() {}
        }
        """,
      ),
      Example(
        """
        class C {
            class var b: Bool { true }
            class func f() {}
        }
        """,
      ),
      Example(
        """
        class C {
            static var b: Bool { true }
            static func f() {}
        }
        """,
      ),
      Example(
        """
        final class C {
            static var b: Bool { true }
            static func f() {}
        }
        """,
      ),
      Example(
        """
        final class C {
            class D {
                class var b: Bool { true }
                class func f() {}
            }
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        final class C {
            ↓class var b: Bool { true }
            ↓class func f() {}
        }
        """,
      ),
      Example(
        """
        class C {
            final class D {
                ↓class var b: Bool { true }
                ↓class func f() {}
            }
        }
        """,
      ),
      Example(
        """
        class C {
            private ↓class var b: Bool { true }
            private ↓class func f() {}
        }
        """,
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        final class C {
            class func f() {}
        }
        """,
      ): Example(
        """
        final class C {
            final class func f() {}
        }
        """,
      ),
      Example(
        """
        final class C {
            class var b: Bool { true }
        }
        """, configuration: ["final_class_modifier": "static"],
      ): Example(
        """
        final class C {
            static var b: Bool { true }
        }
        """,
      ),
    ]
  }

  var options = NonOverridableClassDeclarationOptions()
}

extension NonOverridableClassDeclarationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NonOverridableClassDeclarationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var finalClassScope = Stack<Bool>()

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      finalClassScope.push(node.modifiers.contains(keyword: .final))
      return .visitChildren
    }

    override func visitPost(_: ClassDeclSyntax) {
      _ = finalClassScope.pop()
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      checkViolations(for: node.modifiers, types: "methods")
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      checkViolations(for: node.modifiers, types: "properties")
    }

    private func checkViolations(for modifiers: DeclModifierListSyntax, types: String) {
      guard !modifiers.contains(keyword: .final),
        let classKeyword = modifiers.first(where: { $0.name.text == "class" }),
        case let inFinalClass = finalClassScope.peek() == true,
        inFinalClass || modifiers.contains(keyword: .private)
      else {
        return
      }
      violations.append(
        .init(
          position: classKeyword.positionAfterSkippingLeadingTrivia,
          reason: inFinalClass
            ? "Class \(types) in final classes should themselves be final"
            : "Private class methods and properties should be declared final",
          severity: configuration.severity,
          correction: .init(
            start: classKeyword.positionAfterSkippingLeadingTrivia,
            end: classKeyword.endPositionBeforeTrailingTrivia,
            replacement: configuration.finalClassModifier.rawValue,
          ),
        ),
      )
    }
  }
}
