import SwiftSyntax

struct ProtocolPropertyAccessorsOrderRule {
    static let id = "protocol_property_accessors_order"
    static let name = "Protocol Property Accessors Order"
    static let summary =
        "When declaring properties in protocols, the order of accessors should be `get set`"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("protocol Foo {\n var bar: String { get set }\n }"),
            Example("protocol Foo {\n var bar: String { get }\n }"),
            Example("protocol Foo {\n var bar: String { set }\n }"),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("protocol Foo {\n var bar: String { ↓set get }\n }"),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example("protocol Foo {\n var bar: String { ↓set get }\n }"):
                Example("protocol Foo {\n var bar: String { get set }\n }"),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension ProtocolPropertyAccessorsOrderRule: SwiftSyntaxRule {
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
