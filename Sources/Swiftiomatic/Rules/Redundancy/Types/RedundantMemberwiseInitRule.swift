import SwiftSyntax

struct RedundantMemberwiseInitRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantMemberwiseInitConfiguration()
}

extension RedundantMemberwiseInitRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantMemberwiseInitRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: StructDeclSyntax) {
      // Collect stored properties
      let storedProperties = node.memberBlock.members.compactMap { member -> (String, String)? in
        guard let varDecl = member.decl.as(VariableDeclSyntax.self),
          let binding = varDecl.bindings.first,
          let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
          let typeAnnotation = binding.typeAnnotation
        else { return nil }
        // Skip computed properties
        if binding.accessorBlock != nil { return nil }
        return (pattern.identifier.text, typeAnnotation.type.trimmedDescription)
      }

      guard storedProperties.isNotEmpty else { return }

      // Find initializers
      for member in node.memberBlock.members {
        guard let initDecl = member.decl.as(InitializerDeclSyntax.self) else { continue }

        // Check if parameters match stored properties
        let params = initDecl.signature.parameterClause.parameters
        guard params.count == storedProperties.count else { continue }

        let matches = zip(params, storedProperties).allSatisfy { param, prop in
          let paramName = (param.secondName ?? param.firstName).text
          let paramType = param.type.trimmedDescription
          return paramName == prop.0 && paramType == prop.1
        }

        guard matches else { continue }

        // Check body is just self.x = x assignments
        guard let body = initDecl.body,
          body.statements.count == storedProperties.count,
          body.statements.allSatisfy({ stmt in
            guard
              let exprStmt = stmt.item.as(ExpressionStmtSyntax.self)
                ?? stmt.item.as(ExprSyntax.self).map({ ExpressionStmtSyntax(expression: $0) }),
              let infixExpr =
                (exprStmt.expression.as(InfixOperatorExprSyntax.self)
                  ?? stmt.item.as(InfixOperatorExprSyntax.self)),
              let op = infixExpr.operator.as(AssignmentExprSyntax.self),
              let lhs = infixExpr.leftOperand.as(MemberAccessExprSyntax.self),
              let base = lhs.base?.as(DeclReferenceExprSyntax.self),
              base.baseName.text == "self"
            else { return false }
            _ = op
            return true
          })
        else { continue }

        violations.append(initDecl.initKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
