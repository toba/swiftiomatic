import SwiftiomaticSyntax

struct FoundationModernizationRule {
  static let id = "foundation_modernization"
  static let name = "Foundation Modernization"
  static let summary =
    "Detect Foundation types superseded by modern Swift alternatives"
  static let scope: Scope = .suggest

  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        let text = AttributedString("Hello")
        """
      ),
      Example(
        """
        struct ChatMessage: NotificationCenter.Message {
          let text: String
        }
        """
      ),
      Example(
        """
        func parse(_ data: Data) throws(ParseError) -> Config {
          try decoder.decode(Config.self, from: data)
        }
        """
      ),
      Example("import Foundation"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        let text = ↓NSAttributedString(string: "Hello")
        """
      ),
      Example(
        """
        var text: ↓NSMutableAttributedString = .init()
        """
      ),
      Example(
        """
        let style = ↓NSMutableParagraphStyle()
        """
      ),
      Example(
        """
        static let didUpdate = ↓Notification.Name("didUpdate")
        """
      ),
      Example(
        """
        extension ↓NSNotification.Name {
          static let appLaunched = Self("appLaunched")
        }
        """
      ),
      Example(
        """
        func fetch() -> ↓Result<Data, NetworkError> {
          .success(Data())
        }
        """
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension FoundationModernizationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ViolationMessage {
  fileprivate static func supersededType(_ name: String, replacement: String) -> Self {
    "'\(name)' is superseded by \(replacement)"
  }

  fileprivate static let notificationName: Self =
    "Notification.Name is superseded by NotificationCenter.Message structs"

  fileprivate static let resultReturnType: Self =
    "Result return type may be replaceable with typed throws"
}

private let supersededTypes: [String: String] = [
  "NSAttributedString": "AttributedString (value type, Sendable)",
  "NSMutableAttributedString": "AttributedString (value type, Sendable)",
  "NSParagraphStyle": "AttributedString paragraph attributes",
  "NSMutableParagraphStyle": "AttributedString paragraph attributes",
]

extension FoundationModernizationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    // MARK: - Superseded NS types (as type annotations)

    override func visitPost(_ node: IdentifierTypeSyntax) {
      let name = node.name.text
      if let replacement = supersededTypes[name] {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            message: .supersededType(name, replacement: replacement),
            confidence: .high,
            suggestion: "Use AttributedString instead",
          )
        )
      }
    }

    // MARK: - Superseded NS types (as expressions, e.g. constructor calls)

    override func visitPost(_ node: DeclReferenceExprSyntax) {
      let name = node.baseName.text
      if let replacement = supersededTypes[name] {
        // Skip if already caught as type annotation
        if node.parent?.is(IdentifierTypeSyntax.self) == true { return }
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            message: .supersededType(name, replacement: replacement),
            confidence: .high,
            suggestion: "Use AttributedString instead",
          )
        )
      }
    }

    // MARK: - Notification.Name

    override func visitPost(_ node: MemberTypeSyntax) {
      let base = node.baseType.trimmedDescription
      let member = node.name.text
      if (base == "Notification" || base == "NSNotification") && member == "Name" {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            message: .notificationName,
            confidence: .high,
            suggestion: "Define a NotificationCenter.Message struct instead",
          )
        )
      }
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
      guard let base = node.base else { return }
      let baseText = base.trimmedDescription
      let member = node.declName.baseName.text
      if (baseText == "Notification" || baseText == "NSNotification") && member == "Name" {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            message: .notificationName,
            confidence: .high,
            suggestion: "Define a NotificationCenter.Message struct instead",
          )
        )
      }
    }

    // MARK: - Result return types

    override func visitPost(_ node: FunctionDeclSyntax) {
      guard let returnType = node.signature.returnClause?.type,
        let genericType = returnType.as(IdentifierTypeSyntax.self),
        genericType.name.text == "Result",
        let genericArgs = genericType.genericArgumentClause,
        genericArgs.arguments.count == 2
      else { return }

      violations.append(
        SyntaxViolation(
          position: returnType.positionAfterSkippingLeadingTrivia,
          message: .resultReturnType,
          confidence: .medium,
          suggestion: "Consider using typed throws instead of Result return type",
        )
      )
    }
  }
}
