import SwiftSyntax

struct InlinableGenericRule {
  static let id = "inlinable_generic"
  static let name = "Inlinable Generic"
  static let summary =
    "Detects public generic functions missing @inlinable — prevents specialization by callers"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("@inlinable public func transform<T>(_ value: T) -> T { value }"),
      Example("func transform<T>(_ value: T) -> T { value }"),
      Example("public func concrete(_ value: Int) -> Int { value }"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓public func transform<T>(_ value: T) -> T { value }"),
      Example("↓public func process(_ value: some Equatable) -> Bool { true }"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension InlinableGenericRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension InlinableGenericRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      let isPublic = node.modifiers.contains { $0.name.text == "public" }
      guard isPublic else { return }

      let hasGenericParams = node.genericParameterClause != nil
      let hasSomeParams = node.signature.parameterClause.parameters.contains {
        $0.type.trimmedDescription.hasPrefix("some ")
      }
      guard hasGenericParams || hasSomeParams else { return }

      let hasInlinable = node.attributes.contains {
        $0.trimmedDescription.contains("@inlinable")
      }
      guard !hasInlinable else { return }

      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason:
            "Public generic function '\(node.name.text)' without @inlinable — prevents specialization by callers",
          severity: .warning,
          confidence: .low,
          suggestion: "Add @inlinable if this is a library module to enable generic specialization",
        ),
      )
    }
  }
}
