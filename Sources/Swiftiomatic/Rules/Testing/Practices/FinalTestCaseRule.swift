import SwiftSyntax

struct FinalTestCaseRule {
  var options = FinalTestCaseOptions()

  static let configuration = FinalTestCaseConfiguration()
}

extension FinalTestCaseRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension FinalTestCaseRule {}

extension FinalTestCaseRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ClassDeclSyntax) {
      if node.isNonFinalTestClass(parentClasses: configuration.testParentClasses) {
        violations.append(node.name.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
      var newNode = node
      if node.isNonFinalTestClass(parentClasses: configuration.testParentClasses) {
        numberOfCorrections += 1
        let finalModifier = DeclModifierSyntax(name: .keyword(.final))
        newNode =
          if node.modifiers.isEmpty {
            node
              .with(
                \.modifiers,
                [
                  finalModifier.with(
                    \.leadingTrivia,
                    node.classKeyword.leadingTrivia,
                  )
                ],
              )
              .with(\.classKeyword.leadingTrivia, .space)
          } else {
            node
              .with(
                \.modifiers,
                node.modifiers + [finalModifier.with(\.trailingTrivia, .space)],
              )
          }
      }
      return super.visit(newNode)
    }
  }
}

extension ClassDeclSyntax {
  fileprivate func isNonFinalTestClass(parentClasses: Set<String>) -> Bool {
    inheritanceClause.containsInheritedType(inheritedTypes: parentClasses)
      && !modifiers.contains(keyword: .open)
      && !modifiers.contains(keyword: .final)
  }
}
