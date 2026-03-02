@_spi(Diagnostics) import SwiftParser
@_spi(RawSyntax) import SwiftSyntax

struct RedundantSelfRule {
    static let id = "redundant_self"
    static let name = "Redundant Self"
    static let summary = "Explicit use of 'self' is not required"
    static let isCorrectable = true
    static let isOptIn = true
    static let deprecatedAliases: Set<String> = ["redundant_self_in_closure"]
    static var nonTriggeringExamples: [Example] {
        RedundantSelfRuleExamples.nonTriggeringExamples
    }
    static var triggeringExamples: [Example] {
        RedundantSelfRuleExamples.triggeringExamples
    }
    static var corrections: [Example: Example] {
        RedundantSelfRuleExamples.corrections
    }
  var options = RedundantSelfOptions()

}

extension RedundantSelfRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantSelfRule {}

private enum TypeDeclarationKind {
  case likeStruct, likeClass, `extension`
}

private enum ClosureExprType {
  case anonymousCall, functionArgument
}

private enum SelfCaptureKind {
  case strong, weak, uncaptured
}

extension RedundantSelfRule {
  fileprivate final class Visitor: DeclaredIdentifiersTrackingVisitor<OptionsType> {
    private var typeDeclarations = Stack<TypeDeclarationKind>()
    private var closureExprScopes = Stack<(ClosureExprType, SelfCaptureKind)>()
    private var initializerScopes = Stack<Bool>()

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visit(_: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
      typeDeclarations.push(.likeClass)
      return .visitChildren
    }

    override func visitPost(_: ActorDeclSyntax) {
      typeDeclarations.pop()
    }

    override func visit(_: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
      typeDeclarations.push(.likeClass)
      return .visitChildren
    }

    override func visitPost(_: ClassDeclSyntax) {
      typeDeclarations.pop()
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
      let captureType: SelfCaptureKind =
        if let selfItem = node.signature?.capture?.items.first(where: \.capturesSelf) {
          selfItem.capturesWeakly ? .weak : .strong
        } else {
          .uncaptured
        }
      let exprType: ClosureExprType =
        if node.keyPathInParent == \FunctionCallExprSyntax.calledExpression {
          .anonymousCall
        } else {
          .functionArgument
        }
      closureExprScopes.push((exprType, captureType))
      return .visitChildren
    }

    override func visitPost(_: ClosureExprSyntax) {
      closureExprScopes.pop()
    }

    override func visit(_: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
      typeDeclarations.push(.likeStruct)
      return .visitChildren
    }

    override func visitPost(_: EnumDeclSyntax) {
      typeDeclarations.pop()
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
      if node.extendedType.isOptionalType {
        typeDeclarations.push(.extension)
      }
      return .visitChildren
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
      if node.extendedType.isOptionalType {
        typeDeclarations.pop()
      }
    }

    override func visit(_: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
      initializerScopes.push(true)
      return .visitChildren
    }

    override func visitPost(_: InitializerDeclSyntax) {
      initializerScopes.pop()
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
      if configuration.keepInInitializers, initializerScopes.peek() == true {
        return
      }
      if closureExprScopes.isNotEmpty, !isSelfRedundant {
        return
      }
      if configuration.onlyInClosures, closureExprScopes.isEmpty {
        return
      }
      if typeDeclarations.peek() == .extension, node.isBaseSelf,
        hasSeenDeclaration(for: "self")
      {
        return
      }
      let declName = node.declName.baseName.text
      if !hasSeenDeclaration(for: declName), node.isBaseSelf, declName != "init" {
        violations.append(
          at: node.positionAfterSkippingLeadingTrivia,
          correction: .init(
            start: node.positionAfterSkippingLeadingTrivia,
            end: node.endPositionBeforeTrailingTrivia,
            replacement: node.declName.baseName.needsEscaping
              ? "`\(declName)`"
              : declName,
          ),
        )
      }
    }

    override func visit(_: StructDeclSyntax) -> SyntaxVisitorContinueKind {
      typeDeclarations.push(.likeStruct)
      return .visitChildren
    }

    override func visitPost(_: StructDeclSyntax) {
      typeDeclarations.pop()
    }

    private var isSelfRedundant: Bool {
      if typeDeclarations.peek() == .likeStruct {
        return true
      }
      guard let (closureType, selfCapture) = closureExprScopes.peek() else {
        return false
      }
      return closureType == .anonymousCall
        || selfCapture == .strong
        || selfCapture == .weak
    }
  }
}

extension TokenSyntax {
  fileprivate var needsEscaping: Bool {
    [UInt8](text.utf8).withUnsafeBufferPointer {
      if let keyword = Keyword(SyntaxText(baseAddress: $0.baseAddress, count: text.count)) {
        return TokenKind.keyword(keyword).isLexerClassifiedKeyword
      }
      return false
    }
  }
}
