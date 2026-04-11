import SwiftSyntax

struct StaticOperatorRule {
  static let id = "static_operator"
  static let name = "Static Operator"
  static let summary = "Operators should be declared as static functions, not free functions"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        class A: Equatable {
          static func == (lhs: A, rhs: A) -> Bool {
            return false
          }
        """,
      ),
      Example(
        """
        class A<T>: Equatable {
            static func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
                return false
            }
        """,
      ),
      Example(
        """
        public extension Array where Element == Rule {
          static func == (lhs: Array, rhs: Array) -> Bool {
            if lhs.count != rhs.count { return false }
            return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
          }
        }
        """,
      ),
      Example(
        """
        private extension Optional where Wrapped: Comparable {
          static func < (lhs: Optional, rhs: Optional) -> Bool {
            switch (lhs, rhs) {
            case let (lhs?, rhs?):
              return lhs < rhs
            case (nil, _?):
              return true
            default:
              return false
            }
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
        ↓func == (lhs: A, rhs: A) -> Bool {
          return false
        }
        """,
      ),
      Example(
        """
        ↓func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
          return false
        }
        """,
      ),
      Example(
        """
        ↓func == (lhs: [Rule], rhs: [Rule]) -> Bool {
          if lhs.count != rhs.count { return false }
          return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
        }
        """,
      ),
      Example(
        """
        private ↓func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
          switch (lhs, rhs) {
          case let (lhs?, rhs?):
            return lhs < rhs
          case (nil, _?):
            return true
          default:
            return false
          }
        }
        """,
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension StaticOperatorRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension StaticOperatorRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      if node.isFreeFunction, node.isOperator {
        violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension FunctionDeclSyntax {
  fileprivate var isFreeFunction: Bool {
    parent?.is(CodeBlockItemSyntax.self) ?? false
  }

  fileprivate var isOperator: Bool {
    switch name.tokenKind {
    case .binaryOperator:
      return true
    default:
      return false
    }
  }
}
