import SwiftiomaticSyntax

extension NoLabelsInCasePatternsRule {
  static var nonTriggeringExamples: [Example] {
    [
      // No labels at all
      Example(
        """
        switch treeNode {
        case .root(let data):
            break
        }
        """
      ),
      // Label differs from bound name — not redundant
      Example(
        """
        switch value {
        case .foo(bar: let x):
            break
        }
        """
      ),
      // Enum without associated values
      Example(
        """
        switch direction {
        case .north:
            break
        }
        """
      ),
      // Wildcard pattern — not a label match
      Example(
        """
        switch value {
        case .foo(bar: _):
            break
        }
        """
      ),
      // Mixed: one label matches, one doesn't — only the matching one triggers
      // (the non-matching argument is fine)
      Example(
        """
        switch value {
        case .pair(first: let x, second: let second):
            break
        }
        """,
        isExcludedFromDocumentation: true
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // Single redundant label
      Example(
        """
        switch value {
        case .leaf(↓element: let element):
            break
        }
        """
      ),
      // Multiple redundant labels
      Example(
        """
        switch treeNode {
        case .subtree(↓left: let left, ↓right: let right):
            break
        }
        """
      ),
      // Redundant label with `var`
      Example(
        """
        switch value {
        case .item(↓name: var name):
            break
        }
        """
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        switch value {
        case .leaf(↓element: let element):
            break
        }
        """
      ): Example(
        """
        switch value {
        case .leaf(let element):
            break
        }
        """
      ),
      Example(
        """
        switch treeNode {
        case .subtree(↓left: let left, ↓right: let right):
            break
        }
        """
      ): Example(
        """
        switch treeNode {
        case .subtree(let left, let right):
            break
        }
        """
      ),
      Example(
        """
        switch value {
        case .item(↓name: var name):
            break
        }
        """
      ): Example(
        """
        switch value {
        case .item(var name):
            break
        }
        """
      ),
    ]
  }
}
