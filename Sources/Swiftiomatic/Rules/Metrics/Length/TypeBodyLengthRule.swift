import Foundation
import SwiftSyntax

struct TypeBodyLengthRule {
  var options = TypeBodyLengthOptions()

  static let configuration = TypeBodyLengthConfiguration()
}

extension TypeBodyLengthRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension TypeBodyLengthRule {
  fileprivate final class Visitor: BodyLengthVisitor<OptionsType> {
    override func visitPost(_ node: ActorDeclSyntax) {
      if !configuration.excludedTypes.contains(.actor) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
      if !configuration.excludedTypes.contains(.class) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: EnumDeclSyntax) {
      if !configuration.excludedTypes.contains(.enum) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
      if !configuration.excludedTypes.contains(.extension) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
      if !configuration.excludedTypes.contains(.protocol) {
        collectViolation(node)
      }
    }

    override func visitPost(_ node: StructDeclSyntax) {
      if !configuration.excludedTypes.contains(.struct) {
        collectViolation(node)
      }
    }

    private func collectViolation(_ node: some DeclGroupSyntax) {
      registerViolations(
        leftBrace: node.memberBlock.leftBrace,
        rightBrace: node.memberBlock.rightBrace,
        violationNode: node.introducer,
        objectName: node.introducer.text.capitalized,
      )
    }
  }
}
