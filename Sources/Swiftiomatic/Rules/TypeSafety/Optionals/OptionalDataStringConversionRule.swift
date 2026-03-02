import SwiftSyntax

struct OptionalDataStringConversionRule {
    static let id = "optional_data_string_conversion"
    static let name = "Optional Data -> String Conversion"
    static let summary = "Prefer failable `String(bytes:encoding:)` initializer when converting `Data` to `String`"
    static var nonTriggeringExamples: [Example] {
        [
              Example("String(data: data, encoding: .utf8)"),
              Example("String(bytes: data, encoding: .utf8)"),
              Example("String(UTF8.self)"),
              Example("String(a, b, c, UTF8.self)"),
              Example("String(decoding: data, encoding: UTF8.self)"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("String(decoding: data, as: UTF8.self)")
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension OptionalDataStringConversionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension OptionalDataStringConversionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DeclReferenceExprSyntax) {
      if node.baseName.text == "String",
        let parent = node.parent?.as(FunctionCallExprSyntax.self),
        parent.arguments.map(\.label?.text) == ["decoding", "as"],
        let expr = parent.arguments.last?.expression.as(MemberAccessExprSyntax.self),
        expr.base?.description == "UTF8",
        expr.declName.baseName.description == "self"
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
