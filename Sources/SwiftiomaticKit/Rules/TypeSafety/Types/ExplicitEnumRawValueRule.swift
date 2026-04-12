import SwiftiomaticSyntax

struct ExplicitEnumRawValueRule {
  static let id = "explicit_enum_raw_value"
  static let name = "Explicit Enum Raw Value"
  static let summary = "Enums should be explicitly assigned their raw values"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        enum Numbers {
          case int(Int)
          case short(Int16)
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
        enum Numbers: Double {
          case one = 1.1
          case two = 2.2
        }
        """,
      ),
      Example(
        """
        enum Numbers: String {
          case one = "one"
          case two = "two"
        }
        """,
      ),
      Example(
        """
        protocol Algebra {}
        enum Numbers: Algebra {
          case one
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        enum Numbers: Int {
          case one = 10, ↓two, three = 30
        }
        """,
      ),
      Example(
        """
        enum Numbers: NSInteger {
          case ↓one
        }
        """,
      ),
      Example(
        """
        enum Numbers: String {
          case ↓one
          case ↓two
        }
        """,
      ),
      Example(
        """
        enum Numbers: String {
           case ↓one, two = "two"
        }
        """,
      ),
      Example(
        """
        enum Numbers: Decimal {
          case ↓one, ↓two
        }
        """,
      ),
      Example(
        """
        enum Outer {
            enum Numbers: Decimal {
              case ↓one, ↓two
            }
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension ExplicitEnumRawValueRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ExplicitEnumRawValueRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: EnumCaseElementSyntax) {
      if node.rawValue == nil, node.enclosingEnum()?.supportsRawValues == true {
        violations.append(node.name.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension SyntaxProtocol {
  fileprivate func enclosingEnum() -> EnumDeclSyntax? {
    if let node = `as`(EnumDeclSyntax.self) {
      return node
    }

    return parent?.enclosingEnum()
  }
}
