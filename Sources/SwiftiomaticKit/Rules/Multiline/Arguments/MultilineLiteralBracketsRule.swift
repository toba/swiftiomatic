import Foundation
import SwiftSyntax

struct MultilineLiteralBracketsRule {
  static let id = "multiline_literal_brackets"
  static let name = "Multiline Literal Brackets"
  static let summary = "Multiline literals should have their surrounding brackets in a new line"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        let trio = ["harry", "ronald", "hermione"]
        let houseCup = ["gryffindor": 460, "hufflepuff": 370, "ravenclaw": 410, "slytherin": 450]
        """,
      ),
      Example(
        """
        let trio = [
            "harry",
            "ronald",
            "hermione"
        ]
        let houseCup = [
            "gryffindor": 460,
            "hufflepuff": 370,
            "ravenclaw": 410,
            "slytherin": 450
        ]
        """,
      ),
      Example(
        """
        let trio = [
            "harry", "ronald", "hermione"
        ]
        let houseCup = [
            "gryffindor": 460, "hufflepuff": 370,
            "ravenclaw": 410, "slytherin": 450
        ]
        """,
      ),
      Example(
        """
        _ = [
            1,
            2,
            3,
            4,
            5, 6,
            7, 8, 9
        ]
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        let trio = [↓"harry",
                    "ronald",
                    "hermione"
        ]
        """,
      ),
      Example(
        """
        let houseCup = [↓"gryffindor": 460, "hufflepuff": 370,
                        "ravenclaw": 410, "slytherin": 450
        ]
        """,
      ),
      Example(
        """
        let houseCup = [↓"gryffindor": 460,
                        "hufflepuff": 370,
                        "ravenclaw": 410,
                        "slytherin": 450↓]
        """,
      ),
      Example(
        """
        let trio = [
            "harry",
            "ronald",
            "hermione"↓]
        """,
      ),
      Example(
        """
        let houseCup = [
            "gryffindor": 460, "hufflepuff": 370,
            "ravenclaw": 410, "slytherin": 450↓]
        """,
      ),
      Example(
        """
        class Hogwarts {
            let houseCup = [
                "gryffindor": 460, "hufflepuff": 370,
                "ravenclaw": 410, "slytherin": 450↓]
        }
        """,
      ),
      Example(
        """
        _ = [
            1,
            2,
            3,
            4,
            5, 6,
            7, 8, 9↓]
        """,
      ),
      Example(
        """
        _ = [↓1, 2, 3,
             4, 5, 6,
             7, 8, 9
        ]
        """,
      ),
      Example(
        """
        class Hogwarts {
            let houseCup = [
                "gryffindor": 460, "hufflepuff": 370,
                "ravenclaw": 410, "slytherin": slytherinPoints.filter {
                    $0.isValid
                }.sum()↓]
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension MultilineLiteralBracketsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension MultilineLiteralBracketsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ArrayExprSyntax) {
      validate(
        node,
        openingToken: node.leftSquare,
        closingToken: node.rightSquare,
        firstElement: node.elements.first?.expression,
        lastElement: node.elements.last?.expression,
      )
    }

    override func visitPost(_ node: DictionaryExprSyntax) {
      switch node.content {
      case .colon:
        break
      case .elements(let elements):
        validate(
          node,
          openingToken: node.leftSquare,
          closingToken: node.rightSquare,
          firstElement: elements.first?.key,
          lastElement: elements.last?.value,
        )
      }
    }

    private func validate(
      _ node: some ExprSyntaxProtocol,
      openingToken: TokenSyntax,
      closingToken: TokenSyntax,
      firstElement: (some ExprSyntaxProtocol)?,
      lastElement: (some ExprSyntaxProtocol)?,
    ) {
      guard let firstElement, let lastElement,
        isMultiline(node)
      else {
        return
      }

      if areOnTheSameLine(openingToken, firstElement) {
        // don't skip trivia to keep violations in the same position as the legacy implementation
        violations.append(firstElement.position)
      }

      if areOnTheSameLine(lastElement, closingToken) {
        violations.append(closingToken.positionAfterSkippingLeadingTrivia)
      }
    }

    private func isMultiline(_ node: some ExprSyntaxProtocol) -> Bool {
      let startLocation =
        locationConverter
        .location(for: node.positionAfterSkippingLeadingTrivia)
      let endLocation = locationConverter.location(for: node.endPositionBeforeTrailingTrivia)

      return endLocation.line > startLocation.line
    }

    private func areOnTheSameLine(_ first: some SyntaxProtocol, _ second: some SyntaxProtocol)
      -> Bool
    {
      let firstLocation =
        locationConverter
        .location(for: first.endPositionBeforeTrailingTrivia)
      let secondLocation = locationConverter.location(
        for: second.positionAfterSkippingLeadingTrivia,
      )

      return firstLocation.line == secondLocation.line
    }
  }
}
