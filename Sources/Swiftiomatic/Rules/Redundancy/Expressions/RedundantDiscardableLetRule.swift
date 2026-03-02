import SwiftSyntax

struct RedundantDiscardableLetRule {
  var options = RedundantDiscardableLetOptions()

  static let configuration = RedundantDiscardableLetConfiguration()
}

extension RedundantDiscardableLetRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantDiscardableLetRule {
  private enum CodeBlockKind {
    case normal
    case view
  }

  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var codeBlockScopes = Stack<CodeBlockKind>()

    override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
      codeBlockScopes.push(node.isViewBody || node.isPreviewProviderBody ? .view : .normal)
      return .visitChildren
    }

    override func visitPost(_: AccessorBlockSyntax) {
      codeBlockScopes.pop()
    }

    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
      codeBlockScopes.push(
        node.isViewBuilderFunctionBody || codeBlockScopes.peek() == .view ? .view : .normal,
      )
      return .visitChildren
    }

    override func visitPost(_: CodeBlockSyntax) {
      codeBlockScopes.pop()
    }

    override func visit(_: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
      codeBlockScopes.push(codeBlockScopes.peek() == .view ? .view : .normal)
      return .visitChildren
    }

    override func visitPost(_: CodeBlockItemListSyntax) {
      codeBlockScopes.pop()
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
      codeBlockScopes.push(node.isPreviewMacroBody ? .view : .normal)
      return .visitChildren
    }

    override func visitPost(_: ClosureExprSyntax) {
      codeBlockScopes.pop()
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      if codeBlockScopes.peek() != .view || !configuration.ignoreSwiftUIViewBodies,
        node.bindingSpecifier.tokenKind == .keyword(.let),
        let binding = node.bindings.onlyElement,
        binding.pattern.is(WildcardPatternSyntax.self),
        binding.typeAnnotation == nil,
        !node.modifiers.contains(where: { $0.name.text == "async" })
      {
        violations.append(
          SyntaxViolation(
            position: node.bindingSpecifier.positionAfterSkippingLeadingTrivia,
            correction: .init(
              start: node.bindingSpecifier.positionAfterSkippingLeadingTrivia,
              end: binding.pattern.positionAfterSkippingLeadingTrivia,
              replacement: "",
            ),
          ),
        )
      }
    }
  }
}

extension AccessorBlockSyntax {
  fileprivate var isViewBody: Bool {
    if let binding = parent?.as(PatternBindingSyntax.self),
      binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body",
      let type = binding.typeAnnotation?.type.as(SomeOrAnyTypeSyntax.self)
    {
      return type.isView && binding.parent?.parent?.is(VariableDeclSyntax.self) == true
    }
    return false
  }

  fileprivate var isPreviewProviderBody: Bool {
    guard let binding = parent?.as(PatternBindingSyntax.self),
      binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "previews",
      let bindingList = binding.parent?.as(PatternBindingListSyntax.self),
      let variableDecl = bindingList.parent?.as(VariableDeclSyntax.self),
      variableDecl.modifiers.contains(keyword: .static),
      variableDecl.bindingSpecifier.tokenKind == .keyword(.var),
      let type = binding.typeAnnotation?.type.as(SomeOrAnyTypeSyntax.self)
    else {
      return false
    }

    return type.isView
  }
}

extension CodeBlockSyntax {
  fileprivate var isViewBuilderFunctionBody: Bool {
    guard let functionDecl = parent?.as(FunctionDeclSyntax.self),
      functionDecl.attributes.contains(attributeNamed: "ViewBuilder")
    else {
      return false
    }
    return functionDecl.signature.returnClause?.type.as(SomeOrAnyTypeSyntax.self)?
      .isView ?? false
  }
}

extension ClosureExprSyntax {
  fileprivate var isPreviewMacroBody: Bool {
    parent?.as(MacroExpansionExprSyntax.self)?.macroName.text == "Preview"
  }
}

extension SomeOrAnyTypeSyntax {
  fileprivate var isView: Bool {
    someOrAnySpecifier.text == "some"
      && constraint.as(IdentifierTypeSyntax.self)?.name.text == "View"
  }
}
