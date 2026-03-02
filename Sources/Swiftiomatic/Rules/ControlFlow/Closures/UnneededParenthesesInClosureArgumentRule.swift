import SwiftSyntax

struct UnneededParenthesesInClosureArgumentRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UnneededParenthesesInClosureArgumentConfiguration()
}

extension UnneededParenthesesInClosureArgumentRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension UnneededParenthesesInClosureArgumentRule {}

extension UnneededParenthesesInClosureArgumentRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClosureSignatureSyntax) {
      guard let clause = node.parameterClause?.as(ClosureParameterClauseSyntax.self),
        clause.parameters.isNotEmpty,
        clause.parameters.allSatisfy({ $0.type == nil })
      else {
        return
      }

      violations.append(clause.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
      guard let clause = node.parameterClause?.as(ClosureParameterClauseSyntax.self),
        clause.parameters.isNotEmpty,
        clause.parameters.allSatisfy({ $0.type == nil })
      else {
        return super.visit(node)
      }

      let items = clause.parameters.enumerated().compactMap {
        idx, param -> ClosureShorthandParameterSyntax? in
        let name = param.firstName
        let isLast = idx == clause.parameters.count - 1
        return ClosureShorthandParameterSyntax(
          name: name,
          trailingComma: isLast ? nil : .commaToken(trailingTrivia: Trivia(pieces: [.spaces(1)])),
        )
      }

      numberOfCorrections += 1
      let paramList = ClosureShorthandParameterListSyntax(items).with(
        \.trailingTrivia,
        .spaces(1),
      )
      return super.visit(node.with(\.parameterClause, .init(paramList)))
    }
  }
}
