import SwiftSyntax

struct CodableEnumRawValueRule {
  static let id = "codable_enum_raw_value"
  static let name = "Codable Enum Raw Value"
  static let summary = "Camel cased cases of Codable String enums should have raw values"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        enum Numbers: Codable {
          case int(Int)
          case short(Int16)
        }
        """,
      ),
      Example(
        """
        enum Numbers: Int, Codable {
          case one = 1
          case two = 2
        }
        """,
      ),
      Example(
        """
        enum Numbers: Double, Codable {
          case one = 1.1
          case two = 2.2
        }
        """,
      ),
      Example(
        """
        enum Numbers: String, Codable {
          case one = "one"
          case two = "two"
        }
        """,
      ),
      Example(
        """
        enum Status: String, Codable {
            case OK, ACCEPTABLE
        }
        """,
      ),
      Example(
        """
        enum Status: String, Codable {
            case ok
            case maybeAcceptable = "maybe_acceptable"
        }
        """,
      ),
      Example(
        """
        enum Status: String {
            case ok
            case notAcceptable
            case maybeAcceptable = "maybe_acceptable"
        }
        """,
      ),
      Example(
        """
        enum Status: Int, Codable {
            case ok
            case notAcceptable
            case maybeAcceptable = -1
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        enum Status: String, Codable {
            case ok
            case ↓notAcceptable
            case maybeAcceptable = "maybe_acceptable"
        }
        """,
      ),
      Example(
        """
        enum Status: String, Decodable {
           case ok
           case ↓notAcceptable
           case maybeAcceptable = "maybe_acceptable"
        }
        """,
      ),
      Example(
        """
        enum Status: String, Encodable {
           case ok
           case ↓notAcceptable
           case maybeAcceptable = "maybe_acceptable"
        }
        """,
      ),
      Example(
        """
        enum Status: String, Codable {
            case ok
            case ↓notAcceptable
            case maybeAcceptable = "maybe_acceptable"
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension CodableEnumRawValueRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension CodableEnumRawValueRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private let codableTypes = Set(["Codable", "Decodable", "Encodable"])

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      guard let inheritedTypes = node.inheritanceClause?.inheritedTypes.typeNames,
        !inheritedTypes.isDisjoint(with: codableTypes),
        inheritedTypes.contains("String")
      else {
        return .skipChildren
      }

      return .visitChildren
    }

    override func visitPost(_ node: EnumCaseElementSyntax) {
      guard node.rawValue == nil,
        case let name = node.name.text,
        !name.isUppercase,
        !name.isLowercase
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension InheritedTypeListSyntax {
  fileprivate var typeNames: Set<String> {
    Set(compactMap { $0.type.as(IdentifierTypeSyntax.self) }.map(\.name.text))
  }
}
