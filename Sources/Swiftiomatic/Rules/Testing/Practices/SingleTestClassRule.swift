import SwiftSyntax

struct SingleTestClassRule: SyntaxOnlyRule {
  var options = SingleTestClassOptions()

  static let configuration = SingleTestClassConfiguration()

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
