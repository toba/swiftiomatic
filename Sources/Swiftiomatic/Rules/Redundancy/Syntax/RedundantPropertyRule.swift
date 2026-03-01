import SwiftSyntax

struct RedundantPropertyRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "redundant_property",
    name: "Redundant Property",
    description:
      "A local property assigned and immediately returned can be simplified to a direct return",
    scope: .format,
    nonTriggeringExamples: [
      Example(
        """
        func foo() -> Foo {
          return Foo()
        }
        """,
      ),
      Example(
        """
        func foo() -> Foo {
          let foo = Foo()
          foo.configure()
          return foo
        }
        """,
      ),
      Example(
        """
        func foo() -> Foo {
          var foo = Foo()
          foo.bar = true
          return foo
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        func foo() -> Foo {
          let ↓foo = Foo()
          return foo
        }
        """,
      ),
      Example(
        """
        func bar() -> String {
          let ↓result = "hello"
          return result
        }
        """,
      ),
    ],
    corrections: [
      Example(
        """
        func foo() -> Foo {
          let ↓foo = Foo()
          return foo
        }
        """,
      ): Example(
        """
        func foo() -> Foo {
          return Foo()
        }
        """,
      )
    ],
  )
}

extension RedundantPropertyRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension RedundantPropertyRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: CodeBlockItemListSyntax) {
      for (propertyItem, _) in node.redundantPropertyReturnPairs() {
        guard
          let binding = propertyItem.item.as(VariableDeclSyntax.self)?
            .bindings.first
        else { continue }
        violations.append(binding.pattern.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<ConfigurationType> {
    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
      let pairs = node.redundantPropertyReturnPairs()
      guard pairs.isNotEmpty else { return super.visit(node) }

      // Indices of items to remove (the return statement and the property declaration)
      var removeIndices = Set<Int>()
      var replacements = [(Int, CodeBlockItemSyntax)]()

      for (propertyItem, returnItem) in pairs {
        guard let propIndex = node.index(of: propertyItem),
          let retIndex = node.index(of: returnItem),
          let varDecl = propertyItem.item.as(VariableDeclSyntax.self),
          let binding = varDecl.bindings.first,
          let initializer = binding.initializer
        else { continue }

        numberOfCorrections += 1
        removeIndices.insert(node.distance(from: node.startIndex, to: retIndex))

        // Replace property with return expression
        let returnStmt = ReturnStmtSyntax(
          leadingTrivia: propertyItem.leadingTrivia,
          expression: initializer.value.with(\.leadingTrivia, .space),
          trailingTrivia: propertyItem.trailingTrivia,
        )
        let newItem = propertyItem.with(\.item, CodeBlockItemSyntax.Item(returnStmt))
        replacements.append(
          (node.distance(from: node.startIndex, to: propIndex), newItem),
        )
      }

      var items = Array(node)
      // Apply replacements first (indices don't change)
      for (index, replacement) in replacements {
        items[index] = replacement
      }
      // Remove return statements in reverse order
      for index in removeIndices.sorted().reversed() {
        items.remove(at: index)
      }

      return super.visit(CodeBlockItemListSyntax(items))
    }
  }
}

extension CodeBlockItemListSyntax {
  fileprivate func redundantPropertyReturnPairs()
    -> [(property: Element, returnStmt: Element)]
  {
    var pairs = [(property: Element, returnStmt: Element)]()
    var iterator = makeIterator()
    var previous: Element?

    while let current = iterator.next() {
      defer { previous = current }
      guard let prev = previous else { continue }

      // Check if previous is `let/var name = expr` and current is `return name`
      guard let varDecl = prev.item.as(VariableDeclSyntax.self),
        varDecl.bindings.count == 1,
        let binding = varDecl.bindings.first,
        let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
        binding.initializer != nil,
        let returnStmt = current.item.as(ReturnStmtSyntax.self),
        let returnExpr = returnStmt.expression?.as(DeclReferenceExprSyntax.self),
        returnExpr.baseName.text == pattern.identifier.text
      else { continue }

      pairs.append((prev, current))
    }
    return pairs
  }
}
