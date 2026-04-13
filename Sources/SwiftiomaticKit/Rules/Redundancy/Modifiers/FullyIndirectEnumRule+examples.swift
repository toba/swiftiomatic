import SwiftiomaticSyntax

extension FullyIndirectEnumRule {
  static var nonTriggeringExamples: [Example] {
    [
      // Already indirect on the enum itself
      Example(
        """
        indirect enum Tree {
            case leaf(Int)
            case branch(Tree, Tree)
        }
        """
      ),
      // Not all cases are indirect
      Example(
        """
        enum CompassPoint {
            case north
            indirect case south
            case east
            case west
        }
        """
      ),
      // No cases at all
      Example(
        """
        enum Constants {
            static let foo = 5
            static let bar = "bar"
        }
        """
      ),
      // Single non-indirect case
      Example(
        """
        enum Simple {
            case value(Int)
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // All cases indirect — should use indirect enum
      Example(
        """
        ↓enum Tree {
            indirect case leaf(Int)
            indirect case branch(Tree, Tree)
        }
        """
      ),
      // All cases indirect with access control
      Example(
        """
        public ↓enum DependencyGraphNode {
            internal indirect case userDefined(dependencies: [DependencyGraphNode])
            indirect case synthesized(dependencies: [DependencyGraphNode])
            indirect case other(dependencies: [DependencyGraphNode])
            var x: Int
        }
        """
      ),
      // All cases indirect with attributes
      Example(
        """
        ↓enum Expr {
            @available(*, deprecated) indirect case literal(Int)
            indirect case add(Expr, Expr)
        }
        """
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        ↓enum Tree {
            indirect case leaf(Int)
            indirect case branch(Tree, Tree)
        }
        """
      ): Example(
        """
        indirect enum Tree {
            case leaf(Int)
            case branch(Tree, Tree)
        }
        """
      ),
      Example(
        """
        public ↓enum DependencyGraphNode {
            internal indirect case userDefined(dependencies: [DependencyGraphNode])
            indirect case synthesized(dependencies: [DependencyGraphNode])
            indirect case other(dependencies: [DependencyGraphNode])
            var x: Int
        }
        """
      ): Example(
        """
        public indirect enum DependencyGraphNode {
            internal case userDefined(dependencies: [DependencyGraphNode])
            case synthesized(dependencies: [DependencyGraphNode])
            case other(dependencies: [DependencyGraphNode])
            var x: Int
        }
        """
      ),
      Example(
        """
        ↓enum Expr {
            @available(*, deprecated) indirect case literal(Int)
            indirect case add(Expr, Expr)
        }
        """
      ): Example(
        """
        indirect enum Expr {
            @available(*, deprecated) case literal(Int)
            case add(Expr, Expr)
        }
        """
      ),
    ]
  }
}
