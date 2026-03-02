import SwiftSyntax

struct RedundantStringEnumValueRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantStringEnumValueConfiguration()
}

extension RedundantStringEnumValueRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantStringEnumValueRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumDeclSyntax) {
      guard node.isStringEnum else {
        return
      }

      let enumsWithExplicitValues = node.memberBlock.members
        .flatMap { member -> EnumCaseElementListSyntax in
          guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
            return EnumCaseElementListSyntax([])
          }

          return enumCaseDecl.elements
        }
        .filter { $0.rawValue != nil }

      let redundantMembersPositions =
        enumsWithExplicitValues
        .compactMap { element -> AbsolutePosition? in
          guard
            let stringExpr = element.rawValue?.value
              .as(StringLiteralExprSyntax.self),
            let segment = stringExpr.segments.onlyElement?
              .as(StringSegmentSyntax.self),
            segment.content.text == element.name.text
          else {
            return nil
          }

          return stringExpr.positionAfterSkippingLeadingTrivia
        }

      if redundantMembersPositions.count == enumsWithExplicitValues.count {
        violations.append(contentsOf: redundantMembersPositions)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
      guard node.isStringEnum else {
        return super.visit(node)
      }

      let elements = node.memberBlock.members
        .flatMap { member -> [EnumCaseElementSyntax] in
          guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
            return []
          }
          return enumCaseDecl.elements.filter { $0.rawValue != nil }
        }

      let redundantElements = elements.filter { element in
        guard
          let stringExpr = element.rawValue?.value
            .as(StringLiteralExprSyntax.self),
          let segment = stringExpr.segments.onlyElement?
            .as(StringSegmentSyntax.self)
        else {
          return false
        }
        return segment.content.text == element.name.text
      }

      guard redundantElements.count == elements.count else {
        return super.visit(node)
      }

      var newNode = node
      let newMembers = MemberBlockItemListSyntax(
        newNode.memberBlock.members.map { member in
          guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
            return member
          }
          let newElements = EnumCaseElementListSyntax(
            enumCaseDecl.elements.map { element in
              guard element.rawValue != nil,
                let stringExpr = element.rawValue?.value
                  .as(StringLiteralExprSyntax.self),
                let segment = stringExpr.segments.onlyElement?
                  .as(StringSegmentSyntax.self),
                segment.content.text == element.name.text
              else {
                return element
              }
              numberOfCorrections += 1
              return element.with(\.rawValue, nil)
            },
          )
          let newDecl = enumCaseDecl.with(\.elements, newElements)
          return member.with(\.decl, DeclSyntax(newDecl))
        },
      )
      newNode.memberBlock.members = newMembers
      return super.visit(DeclSyntax(newNode))
    }
  }
}

extension EnumDeclSyntax {
  fileprivate var isStringEnum: Bool {
    guard let inheritanceClause else {
      return false
    }

    return inheritanceClause.inheritedTypes.contains { elem in
      elem.type.as(IdentifierTypeSyntax.self)?.typeName == "String"
    }
  }
}
