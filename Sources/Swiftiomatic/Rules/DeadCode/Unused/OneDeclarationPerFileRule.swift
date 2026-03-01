import SwiftSyntax

struct OneDeclarationPerFileRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "one_declaration_per_file",
    name: "One Declaration per File",
    description: "Only a single declaration is allowed in a file",
    nonTriggeringExamples: [
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
    ],
    triggeringExamples: [
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
    ],
  )
}

extension OneDeclarationPerFileRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension OneDeclarationPerFileRule: OptInRule {}

extension OneDeclarationPerFileRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
