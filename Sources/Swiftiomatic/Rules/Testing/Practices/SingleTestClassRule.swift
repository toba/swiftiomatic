import SwiftSyntax

struct SingleTestClassRule: SyntaxOnlyRule {
    static let id = "single_test_class"
    static let name = "Single Test Class"
    static let summary = "Test files should contain a single QuickSpec or XCTestCase class."
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("class FooTests {  }"),
              Example("class FooTests: QuickSpec {  }"),
              Example("class FooTests: XCTestCase {  }"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
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
            ]
    }
  var options = SingleTestClassOptions()

  func validate(file: SwiftSource) -> [RuleViolation] {
    let classes = Visitor(configuration: options, file: file)
      .walk(tree: file.syntaxTree, handler: \.violations)

    guard classes.count > 1 else { return [] }

    return classes.map { position in
      RuleViolation(
        ruleType: Self.self,
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
