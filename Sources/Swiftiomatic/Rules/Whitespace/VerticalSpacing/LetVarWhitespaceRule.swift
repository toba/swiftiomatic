import SwiftSyntax

struct LetVarWhitespaceRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LetVarWhitespaceConfiguration()

  private static func wrapIntoClass(_ example: Example) -> Example {
    example.with(code: "class C {\n" + example.code + "\n}")
  }
}

extension LetVarWhitespaceRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LetVarWhitespaceRule {}

extension LetVarWhitespaceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberBlockItemListSyntax) {
      collectViolations(from: node, using: \.decl)
    }

    override func visitPost(_ node: CodeBlockItemListSyntax) {
      if node.isInValidContext {
        collectViolations(from: node, using: \.unwrap)
      }
    }

    private func collectViolations<List: SyntaxCollection>(
      from members: List,
      using unwrap: (List.Element) -> any SyntaxProtocol,
    ) {
      for member in members {
        guard case let item = unwrap(member),
          !item.is(MacroExpansionDeclSyntax.self),
          !item.is(MacroExpansionExprSyntax.self),
          let index = members.index(of: member),
          case let nextIndex = members.index(after: index),
          nextIndex != members.endIndex,
          case let nextItem = unwrap(members[members.index(after: index)]),
          !nextItem.is(MacroExpansionDeclSyntax.self),
          !nextItem.is(MacroExpansionExprSyntax.self)
        else {
          continue
        }
        if item.kind != nextItem.kind,
          item.kind == .variableDecl || nextItem.kind == .variableDecl,
          !(item.trailingTrivia + nextItem.leadingTrivia).containsAtLeastTwoNewlines
        {
          violations.append(nextItem.positionAfterSkippingLeadingTrivia)
        }
      }
    }
  }
}

extension CodeBlockItemListSyntax {
  fileprivate var isInValidContext: Bool {
    var next = parent
    while let ancestor = next {
      if [.closureExpr, .codeBlock, .accessorBlock].contains(ancestor.kind) {
        return false
      }
      if [.memberBlock, .sourceFile].contains(ancestor.kind) {
        return true
      }
      next = ancestor.parent
    }
    return false
  }
}

extension Trivia {
  fileprivate var containsAtLeastTwoNewlines: Bool {
    reduce(into: 0) { result, piece in
      if case .newlines(let number) = piece {
        result += number
      }
    } > 1
  }
}

extension CodeBlockItemSyntax {
  fileprivate var unwrap: any SyntaxProtocol {
    switch item {
    case .decl(let decl): decl
    case .stmt(let stmt): stmt
    case .expr(let expr): expr
    }
  }
}
