import SwiftSyntax

struct ProtocolPropertyAccessorsOrderRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "protocol_property_accessors_order",
    name: "Protocol Property Accessors Order",
    description:
      "When declaring properties in protocols, the order of accessors should be `get set`",
    nonTriggeringExamples: [
      Example("protocol Foo {\n var bar: String { get set }\n }"),
      Example("protocol Foo {\n var bar: String { get }\n }"),
      Example("protocol Foo {\n var bar: String { set }\n }"),
    ],
    triggeringExamples: [
      Example("protocol Foo {\n var bar: String { ↓set get }\n }")
    ],
    corrections: [
      Example("protocol Foo {\n var bar: String { ↓set get }\n }"):
        Example("protocol Foo {\n var bar: String { get set }\n }")
    ],
  )
}

extension ProtocolPropertyAccessorsOrderRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ProtocolPropertyAccessorsOrderRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .allExcept(ProtocolDeclSyntax.self, VariableDeclSyntax.self)
    }

    override func visitPost(_ node: AccessorBlockSyntax) {
      guard node.hasViolation else {
        return
      }

      violations.append(node.accessors.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
      guard node.hasViolation else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      let reversedAccessors = AccessorDeclListSyntax(Array(node.accessorsList.reversed()))
      return super.visit(node.with(\.accessors, .accessors(reversedAccessors)))
    }
  }
}

extension AccessorBlockSyntax {
  fileprivate var hasViolation: Bool {
    let accessorsList = accessorsList
    return accessorsList.count == 2
      && accessorsList.allSatisfy { $0.body == nil }
      && accessorsList.first?.accessorSpecifier.tokenKind == .keyword(.set)
  }
}
