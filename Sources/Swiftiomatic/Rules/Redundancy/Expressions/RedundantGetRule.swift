import SwiftSyntax

struct RedundantGetRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantGetConfiguration()
}

extension RedundantGetRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantGetRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AccessorBlockSyntax) {
      guard node.hasRedundantGet else { return }
      let getter = node.accessorsList.first!
      violations.append(getter.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
      guard node.hasRedundantGet,
        let getter = node.accessorsList.first,
        let body = getter.body
      else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return super.visit(
        node.with(\.accessors, .getter(body.statements)),
      )
    }
  }
}

extension AccessorBlockSyntax {
  fileprivate var hasRedundantGet: Bool {
    let list = accessorsList
    // Must have exactly one accessor and it must be `get`
    guard list.count == 1,
      let getter = list.first,
      getter.accessorSpecifier.tokenKind == .keyword(.get)
    else {
      return false
    }
    // Must not have attributes (e.g. @objc)
    guard getter.attributes.isEmpty else { return false }
    // Must not have effectSpecifiers (async/throws)
    guard getter.effectSpecifiers == nil else { return false }
    // Must be inside a computed property or subscript, not a function
    guard
      parent?.is(PatternBindingSyntax.self) == true
        || parent?.is(SubscriptDeclSyntax.self) == true
    else {
      return false
    }
    return true
  }
}
