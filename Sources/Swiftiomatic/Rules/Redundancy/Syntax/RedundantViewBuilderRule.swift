import SwiftSyntax

struct RedundantViewBuilderRule {
    static let id = "redundant_view_builder"
    static let name = "Redundant ViewBuilder"
    static let summary =
        "`@ViewBuilder` is redundant on the `body` property of View/ViewModifier or on single-expression bodies"
    static let scope: Scope = .format
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                """
                struct MyView: View {
                  var body: some View {
                    Text("Hello")
                  }
                }
                """,
            ),
            Example(
                """
                struct MyView: View {
                  @ViewBuilder
                  var content: some View {
                    if showText {
                      Text("Hello")
                    }
                    Text("World")
                  }
                }
                """,
            ),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                struct MyView: View {
                  ↓@ViewBuilder
                  var body: some View {
                    Text("Hello")
                  }
                }
                """,
            ),
            Example(
                """
                struct MyView: View {
                  ↓@ViewBuilder
                  var content: some View {
                    Text("Hello")
                  }
                }
                """,
            ),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example(
                """
                struct MyView: View {
                  ↓@ViewBuilder
                  var body: some View {
                    Text("Hello")
                  }
                }
                """,
            ): Example(
                """
                struct MyView: View {
                  var body: some View {
                    Text("Hello")
                  }
                }
                """,
            ),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension RedundantViewBuilderRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension RedundantViewBuilderRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visitPost(_ node: AttributeSyntax) {
            guard node.isRedundantViewBuilder else { return }
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ node: AttributeListSyntax) -> AttributeListSyntax {
            var modified = false
            let newAttributes = node.filter { element in
                guard case let .attribute(attr) = element,
                      attr.isRedundantViewBuilder
                else {
                    return true
                }
                modified = true
                numberOfCorrections += 1
                return false
            }
            guard modified else { return super.visit(node) }
            return super.visit(newAttributes)
        }
    }
}

extension AttributeSyntax {
    fileprivate var isRedundantViewBuilder: Bool {
        guard attributeName.trimmedDescription == "ViewBuilder" else { return false }

        // Check if decorating `body` property in a View type
        if let varDecl = parent?.parent?.as(VariableDeclSyntax.self),
           varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body"
        {
            // In a View or ViewModifier type — body property has implicit @ViewBuilder
            if let typeDecl = varDecl.nearestEnclosingTypeDecl,
               typeDecl.inheritsFromViewOrViewModifier
            {
                return true
            }
        }

        // Check if decorating `body` function in a ViewModifier type
        if let funcDecl = parent?.parent?.as(FunctionDeclSyntax.self),
           funcDecl.name.text == "body"
        {
            if let typeDecl = funcDecl.nearestEnclosingTypeDecl,
               typeDecl.inheritsFromViewOrViewModifier
            {
                return true
            }
        }

        // Check if body is a single non-conditional expression
        if let varDecl = parent?.parent?.as(VariableDeclSyntax.self),
           let binding = varDecl.bindings.first,
           let accessor = binding.accessorBlock,
           case let .getter(statements) = accessor.accessors,
           statements.count == 1,
           !statements.first!.item.is(IfExprSyntax.self),
           !statements.first!.item.is(SwitchExprSyntax.self)
        {
            return true
        }

        if let funcDecl = parent?.parent?.as(FunctionDeclSyntax.self),
           let body = funcDecl.body,
           body.statements.count == 1,
           !body.statements.first!.item.is(IfExprSyntax.self),
           !body.statements.first!.item.is(SwitchExprSyntax.self)
        {
            return true
        }

        return false
    }
}

extension DeclSyntaxProtocol {
    fileprivate var nearestEnclosingTypeDecl: (any DeclGroupSyntax)? {
        var current: Syntax? = Syntax(self)
        while let node = current?.parent {
            if let typeDecl = node.asProtocol(DeclGroupSyntax.self),
               node.is(StructDeclSyntax.self) || node.is(ClassDeclSyntax.self)
               || node.is(EnumDeclSyntax.self)
            {
                return typeDecl
            }
            current = node
        }
        return nil
    }
}

extension DeclGroupSyntax {
    fileprivate var inheritsFromViewOrViewModifier: Bool {
        guard let inheritanceClause else { return false }
        return inheritanceClause.inheritedTypes.contains { type in
            let name = type.type.trimmedDescription
            return name == "View" || name == "ViewModifier"
        }
    }
}
