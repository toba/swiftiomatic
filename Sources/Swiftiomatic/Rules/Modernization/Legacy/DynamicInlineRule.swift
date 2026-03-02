import SwiftSyntax

struct DynamicInlineRule {
    static let id = "dynamic_inline"
    static let name = "Dynamic Inline"
    static let summary = "Avoid using 'dynamic' and '@inline(__always)' together"
    static var nonTriggeringExamples: [Example] {
        [
              Example("class C {\ndynamic func f() {}}"),
              Example("class C {\n@inline(__always) func f() {}}"),
              Example("class C {\n@inline(never) dynamic func f() {}}"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("class C {\n@inline(__always) dynamic ↓func f() {}\n}"),
              Example("class C {\n@inline(__always) public dynamic ↓func f() {}\n}"),
              Example("class C {\n@inline(__always) dynamic internal ↓func f() {}\n}"),
              Example("class C {\n@inline(__always)\ndynamic ↓func f() {}\n}"),
              Example("class C {\n@inline(__always)\ndynamic\n↓func f() {}\n}"),
            ]
    }
  var options = SeverityOption<Self>(.error)

}

extension DynamicInlineRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DynamicInlineRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      if node.modifiers.contains(where: { $0.name.text == "dynamic" }),
        node.attributes
          .contains(where: { $0.as(AttributeSyntax.self)?.isInlineAlways == true })
      {
        violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension AttributeSyntax {
  fileprivate var isInlineAlways: Bool {
    attributeNameText == "inline"
      && arguments?.firstToken(viewMode: .sourceAccurate)?
        .tokenKind == .identifier("__always")
  }
}
