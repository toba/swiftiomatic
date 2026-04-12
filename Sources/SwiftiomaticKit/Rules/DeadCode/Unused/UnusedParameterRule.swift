import SwiftiomaticSyntax

struct UnusedParameterRule {
  static let id = "unused_parameter"
  static let name = "Unused Parameter"
  static let summary = "Unused function parameters should be removed or replaced with `_`"
  static let isCorrectable = true
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        func f(a: Int) {
            _ = a
        }
        """,
      ),
      Example(
        """
        func f(case: Int) {
            _ = `case`
        }
        """,
      ),
      Example(
        """
        func f(a _: Int) {}
        """,
      ),
      Example(
        """
        func f(_: Int) {}
        """,
      ),
      Example(
        """
        func f(a: Int, b c: String) {
            func g() {
                _ = a
                _ = c
            }
        }
        """,
      ),
      Example(
        """
        func f(a: Int, c: Int) -> Int {
            struct S {
                let b = 1
                func f(a: Int, b: Int = 2) -> Int { a + b }
            }
            return a + c
        }
        """,
      ),
      Example(
        """
        func f(a: Int?) {
            if let a {}
        }
        """,
      ),
      Example(
        """
        func f(a: Int) {
            let a = a
            return a
        }
        """,
      ),
      Example(
        """
        func f(`operator`: Int) -> Int { `operator` }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        func f(↓a: Int) {}
        """,
      ),
      Example(
        """
        func f(↓a: Int, b ↓c: String) {}
        """,
      ),
      Example(
        """
        func f(↓a: Int, b ↓c: String) {
            func g(a: Int, ↓b: Double) {
                _ = a
            }
        }
        """,
      ),
      Example(
        """
        struct S {
            let a: Int

            init(a: Int, ↓b: Int) {
                func f(↓a: Int, b: Int) -> Int { b }
                self.a = f(a: a, b: 0)
            }
        }
        """,
      ),
      Example(
        """
        struct S {
            subscript(a: Int, ↓b: Int) {
                func f(↓a: Int, b: Int) -> Int { b }
                return f(a: a, b: 0)
            }
        }
        """,
      ),
      Example(
        """
        func f(↓a: Int, ↓b: Int, c: Int) -> Int {
            struct S {
                let b = 1
                func f(a: Int, ↓c: Int = 2) -> Int { a + b }
            }
            return S().f(a: c)
        }
        """,
      ),
      Example(
        """
        func f(↓a: Int, c: String) {
            let a = 1
            return a + c
        }
        """,
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        func f(a: Int) {}
        """,
      ): Example(
        """
        func f(a _: Int) {}
        """,
      ),
      Example(
        """
        func f(a b: Int) {}
        """,
      ): Example(
        """
        func f(a _: Int) {}
        """,
      ),
      Example(
        """
        func f(_ a: Int) {}
        """,
      ): Example(
        """
        func f(_: Int) {}
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension UnusedParameterRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

// MARK: Visitor

extension UnusedParameterRule {
  fileprivate final class Visitor: DeclaredIdentifiersTrackingVisitor<OptionsType> {
    private var referencedDeclarations = Set<IdentifierDeclaration>()

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    // MARK: Violation checking

    override func visitPost(_ node: CodeBlockItemListSyntax) {
      let declarations = scope.peek() ?? []
      for declaration in declarations.reversed()
      where !referencedDeclarations.contains(declaration) {
        guard case .parameter(let name) = declaration,
          let previousToken = name.previousToken(viewMode: .sourceAccurate)
        else {
          continue
        }
        let startPosReplacement =
          if previousToken.tokenKind == .wildcard {
            (previousToken.positionAfterSkippingLeadingTrivia, "_")
          } else if case .identifier = previousToken.tokenKind {
            (name.positionAfterSkippingLeadingTrivia, "_")
          } else {
            (name.positionAfterSkippingLeadingTrivia, name.text + " _")
          }
        violations.append(
          .init(
            position: name.positionAfterSkippingLeadingTrivia,
            reason:
              "Parameter '\(name.text)' is unused; consider removing or replacing it with '_'",
            severity: configuration.severity,
            correction: .init(
              start: startPosReplacement.0,
              end: name.endPositionBeforeTrailingTrivia,
              replacement: startPosReplacement.1,
            ),
          ),
        )
      }
      super.visitPost(node)
    }

    // MARK: Reference collection

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      if node.keyPathInParent != \MemberAccessExprSyntax.declName {
        addReference(node.baseName.text)
      }
    }

    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      if node.initializer == nil,
        let id = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
      {
        addReference(id)
      }
    }

    // MARK: Private methods

    private func addReference(_ id: String) {
      for declarations in scope.reversed() {
        if declarations.onlyElement == .lookupBoundary {
          return
        }
        for declaration in declarations.reversed() where declaration.declares(id: id) {
          if referencedDeclarations.insert(declaration).inserted {
            return
          }
        }
      }
    }
  }
}
