import SwiftiomaticSyntax

struct OneDeclarationPerFileRule {
  static let id = "one_declaration_per_file"
  static let name = "One Declaration per File"
  static let summary = "Only a single declaration is allowed in a file"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        actor Foo {}
        """,
      ),
      Example(
        """
        class Foo {}
        extension Foo {}
        """,
      ),
      Example(
        """
        struct S {
            struct N {}
        }
        """,
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        class Foo {}
        ↓class Bar {}
        """,
      ),
      Example(
        """
        protocol Foo {}
        ↓enum Bar {}
        """,
      ),
      Example(
        """
        struct Foo {}
        ↓struct Bar {}
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension OneDeclarationPerFileRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension OneDeclarationPerFileRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var declarationVisited = false
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: ActorDeclSyntax) {
      appendViolationIfNeeded(node: node.actorKeyword)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      appendViolationIfNeeded(node: node.classKeyword)
    }

    override func visitPost(_ node: StructDeclSyntax) {
      appendViolationIfNeeded(node: node.structKeyword)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      appendViolationIfNeeded(node: node.enumKeyword)
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      appendViolationIfNeeded(node: node.protocolKeyword)
    }

    func appendViolationIfNeeded(node: TokenSyntax) {
      if declarationVisited {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
      declarationVisited = true
    }
  }
}
