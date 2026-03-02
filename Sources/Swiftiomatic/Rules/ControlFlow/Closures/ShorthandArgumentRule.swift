import SwiftSyntax

struct ShorthandArgumentRule {
  var options = ShorthandArgumentOptions()

  static let configuration = ShorthandArgumentConfiguration()
}

extension ShorthandArgumentRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ShorthandArgumentRule {}

extension ShorthandArgumentRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClosureExprSyntax) {
      let arguments = ShorthandArgumentCollector().walk(
        tree: node.statements,
        handler: \.arguments,
      )
      if configuration.alwaysDisallowMoreThanOne {
        if arguments.map(\.name).unique.count > 1 {
          violations.append(
            contentsOf: arguments.map {
              SyntaxViolation(
                position: $0.position,
                reason: "Multiple different shorthand arguments should be avoided",
                severity: configuration.severity,
              )
            },
          )
          // In this case, the rule triggers on all shorthand arguments, thus exit here.
          return
        }
      }
      let complexArguments = arguments.filter(\.isComplex)
      if configuration.alwaysDisallowMemberAccess {
        if complexArguments.isNotEmpty {
          violations.append(
            contentsOf: complexArguments.map {
              SyntaxViolation(
                position: $0.position,
                reason: "Accessing members of shorthand arguments should be avoided",
                severity: configuration.severity,
              )
            },
          )
        }
      }
      let startLine = node.startLocation(
        converter: locationConverter,
        afterLeadingTrivia: true,
      )
      .line
      violations.append(
        contentsOf: arguments.compactMap { argument -> SyntaxViolation? in
          if complexArguments.contains(argument) {
            nil
          } else if locationConverter.location(for: argument.position).line
            <= startLine + configuration.allowUntilLineAfterOpeningBrace
          {
            nil
          } else {
            SyntaxViolation(
              position: argument.position,
              reason: """
                References to shorthand arguments too far away from the closure's beginning should \
                be avoided
                """,
              severity: configuration.severity,
            )
          }
        },
      )
    }
  }
}

private struct ShorthandArgument: Hashable {
  let name: String
  let position: AbsolutePosition
  let isComplex: Bool
}

private final class ShorthandArgumentCollector: SyntaxVisitor {
  private(set) var arguments = Set<ShorthandArgument>()

  init() {
    super.init(viewMode: .sourceAccurate)
  }

  override func visitPost(_ node: DeclReferenceExprSyntax) {
    if case .dollarIdentifier(let name) = node.baseName.tokenKind {
      arguments.insert(
        ShorthandArgument(
          name: name,
          position: node.positionAfterSkippingLeadingTrivia,
          isComplex: node.keyPathInParent == \MemberAccessExprSyntax.base,
        ),
      )
    }
  }

  override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    .skipChildren
  }
}
