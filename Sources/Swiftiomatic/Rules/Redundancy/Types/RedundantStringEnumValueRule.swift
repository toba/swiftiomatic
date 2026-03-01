import SwiftSyntax

struct RedundantStringEnumValueRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "redundant_string_enum_value",
    name: "Redundant String Enum Value",
    description: "String enum values can be omitted when they are equal to the enumcase name",
    nonTriggeringExamples: [
      Example(
        """
        enum Numbers: String {
          case one
          case two
        }
        """,
      ),
      Example(
        """
        enum Numbers: Int {
          case one = 1
          case two = 2
        }
        """,
      ),
      Example(
        """
        enum Numbers: String {
          case one = "ONE"
          case two = "TWO"
        }
        """,
      ),
      Example(
        """
        enum Numbers: String {
          case one = "ONE"
          case two = "two"
        }
        """,
      ),
      Example(
        """
        enum Numbers: String {
          case one, two
        }
        """,
      ),
    ],
    triggeringExamples: [
      Example(
        """
        enum Numbers: String {
          case one = ↓"one"
          case two = ↓"two"
        }
        """,
      ),
      Example(
        """
        enum Numbers: String {
          case one = ↓"one", two = ↓"two"
        }
        """,
      ),
      Example(
        """
        enum Numbers: String {
          case one, two = ↓"two"
        }
        """,
      ),
    ],
    corrections: [
      Example(
        """
        enum Numbers: String {
          case one = ↓"one"
          case two = ↓"two"
        }
        """,
      ): Example(
        """
        enum Numbers: String {
          case one
          case two
        }
        """,
      ),
      Example(
        """
        enum Numbers: String {
          case one, two = ↓"two"
        }
        """,
      ): Example(
        """
        enum Numbers: String {
          case one, two
        }
        """,
      ),
    ],
  )
}

extension RedundantStringEnumValueRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension RedundantStringEnumValueRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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

  fileprivate final class Rewriter: ViolationCollectingRewriter<ConfigurationType> {
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
