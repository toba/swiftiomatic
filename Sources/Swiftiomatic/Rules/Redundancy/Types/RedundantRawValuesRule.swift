import SwiftSyntax

struct RedundantRawValuesRule {
  static let id = "redundant_raw_values"
  static let name = "Redundant Raw Values"
  static let summary =
    "Remove redundant raw string values where the value matches the case name"
  static let isCorrectable = true
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        enum Numbers: String {
          case one
          case two
        }
        """
      ),
      Example(
        """
        enum Numbers: Int {
          case one = 1
          case two = 2
        }
        """
      ),
      Example(
        """
        enum Numbers: String {
          case one = "ONE"
          case two = "TWO"
        }
        """
      ),
      Example(
        """
        enum Foo: String {
          case bar = "quux"
        }
        """
      ),
    ]
  }
  static var triggeringExamples: [Example] {
    [
      Example(
        """
        enum Foo: String {
          case bar = ↓"bar"
          case baz = "quux"
        }
        """
      ),
      Example(
        """
        enum Foo: String {
          case bar = ↓"bar"
          case baz = ↓"baz"
        }
        """
      ),
      Example(
        """
        enum Foo: String {
          case bar, baz = ↓"baz"
        }
        """
      ),
    ]
  }
  static var corrections: [Example: Example] {
    [
      Example(
        """
        enum Foo: String {
          case bar = ↓"bar"
          case baz = "quux"
        }
        """
      ): Example(
        """
        enum Foo: String {
          case bar
          case baz = "quux"
        }
        """
      ),
      Example(
        """
        enum Foo: String {
          case bar = ↓"bar"
          case baz = ↓"baz"
        }
        """
      ): Example(
        """
        enum Foo: String {
          case bar
          case baz
        }
        """
      ),
      Example(
        """
        enum Foo: String {
          case bar, baz = ↓"baz"
        }
        """
      ): Example(
        """
        enum Foo: String {
          case bar, baz
        }
        """
      ),
    ]
  }
  var options = SeverityOption<Self>(.warning)
}

extension RedundantRawValuesRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

// Rewriter intentionally omitted — corrections use visitor-based SyntaxViolation.Correction

extension RedundantRawValuesRule {
  fileprivate static func isRedundantRawValue(_ element: EnumCaseElementSyntax) -> Bool {
    guard
      let stringExpr = element.rawValue?.value.as(StringLiteralExprSyntax.self),
      let segment = stringExpr.segments.onlyElement?.as(StringSegmentSyntax.self)
    else {
      return false
    }
    return segment.content.text == element.name.text
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: EnumDeclSyntax) {
      guard node.isStringEnum else { return }

      for member in node.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
        for element in caseDecl.elements where isRedundantRawValue(element) {
          guard let rawValue = element.rawValue else { continue }
          // Replace from after the case name to after the raw value with nothing
          // This removes ` = "value"`
          violations.append(
            SyntaxViolation(
              position: rawValue.value.positionAfterSkippingLeadingTrivia,
              correction: .init(
                start: element.name.endPositionBeforeTrailingTrivia,
                end: rawValue.endPositionBeforeTrailingTrivia,
                replacement: ""
              )
            )
          )
        }
      }
    }
  }
}

extension EnumDeclSyntax {
  fileprivate var isStringEnum: Bool {
    guard let inheritanceClause else { return false }
    return inheritanceClause.inheritedTypes.contains { elem in
      elem.type.as(IdentifierTypeSyntax.self)?.typeName == "String"
    }
  }
}
