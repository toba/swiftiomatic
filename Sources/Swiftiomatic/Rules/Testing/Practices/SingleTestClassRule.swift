import SwiftSyntax

struct SingleTestClassRule: SyntaxOnlyRule {
  var options = SingleTestClassOptions()

  static let description = RuleDescription(
    identifier: "single_test_class",
    name: "Single Test Class",
    description: "Test files should contain a single QuickSpec or XCTestCase class.",
    isOptIn: true,
    nonTriggeringExamples: [
      Example("class FooTests {  }"),
      Example("class FooTests: QuickSpec {  }"),
      Example("class FooTests: XCTestCase {  }"),
    ],
    triggeringExamples: [
      Example(
        """
        ↓class FooTests: QuickSpec {  }
        ↓class BarTests: QuickSpec {  }
        """,
      ),
      Example(
        """
        ↓class FooTests: QuickSpec {  }
        ↓class BarTests: QuickSpec {  }
        ↓class TotoTests: QuickSpec {  }
        """,
      ),
      Example(
        """
        ↓class FooTests: XCTestCase {  }
        ↓class BarTests: XCTestCase {  }
        """,
      ),
      Example(
        """
        ↓class FooTests: XCTestCase {  }
        ↓class BarTests: XCTestCase {  }
        ↓class TotoTests: XCTestCase {  }
        """,
      ),
      Example(
        """
        ↓class FooTests: QuickSpec {  }
        ↓class BarTests: XCTestCase {  }
        """,
      ),
      Example(
        """
        ↓class FooTests: QuickSpec {  }
        ↓class BarTests: XCTestCase {  }
        class TotoTests {  }
        """,
      ),
      Example(
        """
        final ↓class FooTests: QuickSpec {  }
        ↓class BarTests: XCTestCase {  }
        class TotoTests {  }
        """,
      ),
    ],
  )

  func validate(file: SwiftSource) -> [RuleViolation] {
    let classes = Visitor(configuration: options, file: file)
      .walk(tree: file.syntaxTree, handler: \.violations)

    guard classes.count > 1 else { return [] }

    return classes.map { position in
      RuleViolation(
        ruleDescription: Self.description,
        severity: options.severity,
        location: Location(file: file, position: position.position),
        reason: "\(classes.count) test classes found in this file",
      )
    }
  }
}

extension SingleTestClassRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      guard
        node.inheritanceClause.containsInheritedType(
          inheritedTypes: configuration.testParentClasses,
        )
      else {
        return
      }
      violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
