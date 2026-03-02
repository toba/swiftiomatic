import SwiftSyntax

struct ConditionalAssignmentRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ConditionalAssignmentConfiguration()
}

extension ConditionalAssignmentRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ConditionalAssignmentRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: CodeBlockItemListSyntax) {
      var iterator = node.makeIterator()
      var previous: CodeBlockItemSyntax?

      while let current = iterator.next() {
        defer { previous = current }
        guard let prev = previous else { continue }

        // Check for `let x: Type` or `var x: Type` without initializer, followed by if/switch
        guard let varDecl = prev.item.as(VariableDeclSyntax.self),
          let binding = varDecl.bindings.first,
          let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          binding.typeAnnotation != nil,
          binding.initializer == nil
        else { continue }

        let name = pattern.identifier.text

        // Check if current is an if/switch that assigns to `name` in all branches
        if let ifExpr = current.item.as(IfExprSyntax.self) {
          if ifExprAssignsInAllBranches(ifExpr, to: name) {
            violations.append(ifExpr.ifKeyword.positionAfterSkippingLeadingTrivia)
          }
        } else if let switchExpr = current.item.as(SwitchExprSyntax.self) {
          if switchExprAssignsInAllBranches(switchExpr, to: name) {
            violations.append(switchExpr.switchKeyword.positionAfterSkippingLeadingTrivia)
          }
        }
      }
    }

    private func ifExprAssignsInAllBranches(_ node: IfExprSyntax, to name: String) -> Bool {
      // Check if body has exactly one statement that assigns to `name`
      guard branchAssigns(node.body.statements, to: name) else { return false }

      // Must have an else branch
      guard let elseBody = node.elseBody else { return false }

      switch elseBody {
      case .codeBlock(let block):
        return branchAssigns(block.statements, to: name)
      case .ifExpr(let nestedIf):
        return ifExprAssignsInAllBranches(nestedIf, to: name)
      }
    }

    private func switchExprAssignsInAllBranches(_ node: SwitchExprSyntax, to name: String) -> Bool {
      for caseItem in node.cases {
        guard case .switchCase(let switchCase) = caseItem else { continue }
        guard branchAssigns(switchCase.statements, to: name) else { return false }
      }
      return true
    }

    private func branchAssigns(_ statements: CodeBlockItemListSyntax, to name: String) -> Bool {
      guard statements.count == 1,
        let stmt = statements.first
      else { return false }

      if let infixExpr = stmt.item.as(InfixOperatorExprSyntax.self),
        infixExpr.operator.is(AssignmentExprSyntax.self),
        let lhs = infixExpr.leftOperand.as(DeclReferenceExprSyntax.self),
        lhs.baseName.text == name
      {
        return true
      }
      return false
    }
  }
}
