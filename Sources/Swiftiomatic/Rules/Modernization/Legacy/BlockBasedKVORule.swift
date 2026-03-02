import Foundation
import SwiftSyntax

struct BlockBasedKVORule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = BlockBasedKVOConfiguration()
}

extension BlockBasedKVORule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension BlockBasedKVORule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      guard node.modifiers.contains(keyword: .override),
        case let parameterList = node.signature.parameterClause.parameters,
        parameterList.count == 4,
        node.name.text == "observeValue",
        parameterList.map(\.firstName.text) == ["forKeyPath", "of", "change", "context"]
      else {
        return
      }

      let types =
        parameterList
        .map { $0.type.trimmedDescription.replacingOccurrences(of: " ", with: "") }
      let firstTypes = [
        "String?", "Any?", "[NSKeyValueChangeKey:Any]?", "UnsafeMutableRawPointer?",
      ]
      let secondTypes = [
        "String?", "Any?", "Dictionary<NSKeyValueChangeKey,Any>?",
        "UnsafeMutableRawPointer?",
      ]
      if types == firstTypes || types == secondTypes {
        violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
