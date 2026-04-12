import Foundation
import SwiftiomaticSyntax

struct SortEnumCasesRule {
  static let id = "sort_enum_cases"
  static let name = "Sort Enum Cases"
  static let summary = "Enum cases should be sorted"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        enum foo {
            case a
            case b
            case c
        }
        """,
      ),
      Example(
        """
        enum foo {
            case example
            case exBoyfriend
        }
        """,
      ),
      Example(
        """
        enum foo {
            case a
            case B
            case c
        }
        """,
      ),
      Example(
        """
        enum foo {
            case a, b, c
        }
        """,
      ),
      Example(
        """
        enum foo {
            case a
            case b, c
        }
        """,
      ),
      Example(
        """
        enum foo {
            case a(foo: Foo)
            case b(String), c
        }
        """,
      ),
      Example(
        """
        enum foo {
            case a
            case b, C, d
        }
        """,
      ),
      Example(
        """
        @frozen
        enum foo {
            case b
            case a
            case c, f, d
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        enum foo {
            ↓case b
            ↓case a
            case c
        }
        """,
      ),
      Example(
        """
        enum foo {
            ↓case B
            ↓case a
            case c
        }
        """,
      ),
      Example(
        """
        enum foo {
            case ↓b, ↓a, c
        }
        """,
      ),
      Example(
        """
        enum foo {
            case ↓B, ↓a, c
        }
        """,
      ),
      Example(
        """
        enum foo {
            ↓case b, c
            ↓case a
        }
        """,
      ),
      Example(
        """
        enum foo {
            case a
            case b, ↓d, ↓c
        }
        """,
      ),
      Example(
        """
        enum foo {
            case a(foo: Foo)
            case ↓c, ↓b(String)
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension SortEnumCasesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SortEnumCasesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .allExcept(EnumDeclSyntax.self)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      guard !node.attributes.contains(attributeNamed: "frozen") else {
        return .skipChildren
      }

      let cases = node.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
      let sortedCases =
        cases
        .sorted(by: {
          let lhs = $0.elements.first!.name.text
          let rhs = $1.elements.first!.name.text
          return lhs.caseInsensitiveCompare(rhs) == .orderedAscending
        })

      for (sortedCase, currentCase) in zip(sortedCases, cases)
      where sortedCase.elements.first?.name.text
        != currentCase.elements.first?.name
        .text
      {
        violations.append(currentCase.positionAfterSkippingLeadingTrivia)
      }

      return .visitChildren
    }

    override func visitPost(_ node: EnumCaseDeclSyntax) {
      let sortedElements = node.elements.sorted(by: {
        $0.name.text.caseInsensitiveCompare($1.name.text) == .orderedAscending
      })

      for (sortedElement, currentElement) in zip(sortedElements, node.elements)
      where sortedElement.name.text != currentElement.name.text {
        violations.append(currentElement.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
