import SwiftiomaticSyntax
import SwiftSyntax

struct CollectionTypeSelectionRule {
  static let id = "collection_type_selection"
  static let name = "Collection Type Selection"
  static let summary =
    "Suggest swift-collections types (Deque, OrderedSet, Heap) for common Array usage patterns"
  static let scope: Scope = .suggest

  static var nonTriggeringExamples: [Example] {
    [
      // append + removeLast is a stack — Array is fine
      Example(
        """
        var stack: [Int] = []
        stack.append(1)
        stack.removeLast()
        """
      ),
      // removeFirst on Deque is fine
      Example(
        """
        var queue = Deque<Int>()
        queue.append(1)
        queue.removeFirst()
        """
      ),
      // Set.contains is fine — already O(1)
      Example(
        """
        var seen = Set<Int>()
        if !seen.contains(1) {
            seen.insert(1)
        }
        """
      ),
      // sort() without preceding append is fine
      Example(
        """
        var items = [3, 1, 2]
        items.sort()
        """
      ),
      // insert at non-zero index is fine
      Example(
        """
        var items = [1, 2, 3]
        items.insert(0, at: items.count)
        """
      ),
      // contains-then-append with different receivers is fine
      Example(
        """
        if !other.contains(x) {
            items.append(x)
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // insert(at: 0) → Deque
      Example(
        """
        var queue = [1, 2, 3]
        queue.↓insert(4, at: 0)
        """
      ),
      // removeFirst() → Deque
      Example(
        """
        var queue = [1, 2, 3]
        let first = queue.↓removeFirst()
        """
      ),
      // if !contains then append → OrderedSet
      Example(
        """
        ↓if !items.contains(x) {
            items.append(x)
        }
        """
      ),
      // sort() after append() → Heap
      Example(
        """
        items.append(newItem)
        items.↓sort()
        """
      ),
      // sort(by:) after append() → Heap
      Example(
        """
        items.append(newItem)
        items.↓sort(by: { $0.priority < $1.priority })
        """
      ),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension CollectionTypeSelectionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ViolationMessage {
  fileprivate static let insertAtZero: Self =
    ".insert(at: 0) is O(n) on Array — consider Deque from swift-collections for O(1) prepend"

  fileprivate static let removeFirst: Self =
    ".removeFirst() is O(n) on Array — consider Deque from swift-collections for O(1) removal"

  fileprivate static let containsThenAppend: Self =
    "if !contains then append is O(n) per check — consider OrderedSet from swift-collections for O(1) uniqueness"

  fileprivate static let sortAfterAppend: Self =
    ".sort() after .append() is O(n log n) per insertion — consider Heap from swift-collections for O(log n) insert"
}

/// Type names from swift-collections that already provide O(1) for these operations.
private let optimizedCollectionTypes: Set<String> = [
  "Deque", "OrderedSet", "OrderedDictionary", "Heap", "BitSet", "BitArray",
  "TreeSet", "TreeDictionary",
]

extension CollectionTypeSelectionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    /// Variable names whose type annotation or initializer references a swift-collections type.
    private var optimizedVariables = Set<String>()

    // MARK: - Track swift-collections variable declarations

    override func visitPost(_ node: VariableDeclSyntax) {
      for binding in node.bindings {
        guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        else { continue }

        // Check type annotation: `var x: Deque<Int>`
        if let typeAnnotation = binding.typeAnnotation?.type.trimmedDescription,
          optimizedCollectionTypes.contains(where: { typeAnnotation.hasPrefix($0) })
        {
          optimizedVariables.insert(name)
          continue
        }

        // Check initializer: `var x = Deque<Int>()`
        if let initializer = binding.initializer?.value.trimmedDescription,
          optimizedCollectionTypes.contains(where: { initializer.hasPrefix($0) })
        {
          optimizedVariables.insert(name)
        }
      }
    }

    // MARK: - insert(at: 0) and removeFirst()

    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) else {
        return
      }

      // Skip calls on receivers already using swift-collections types
      if let receiver = memberAccess.base?.as(DeclReferenceExprSyntax.self),
        optimizedVariables.contains(receiver.baseName.text)
      {
        return
      }

      let methodName = memberAccess.declName.baseName.text

      // Detect .insert(_, at: 0)
      if methodName == "insert" {
        for arg in node.arguments where arg.label?.text == "at" {
          if let intLiteral = arg.expression.as(IntegerLiteralExprSyntax.self),
            intLiteral.literal.text == "0"
          {
            violations.append(
              SyntaxViolation(
                position: memberAccess.declName.positionAfterSkippingLeadingTrivia,
                message: .insertAtZero,
                confidence: .medium,
                suggestion: "Use Deque for O(1) prepend and pop-front operations",
              )
            )
          }
        }
        return
      }

      // Detect .removeFirst()
      if methodName == "removeFirst", node.arguments.isEmpty {
        violations.append(
          SyntaxViolation(
            position: memberAccess.declName.positionAfterSkippingLeadingTrivia,
            message: .removeFirst,
            confidence: .medium,
            suggestion: "Use Deque for O(1) prepend and pop-front operations",
          )
        )
      }
    }

    // MARK: - if !x.contains(y) { x.append(y) }

    override func visitPost(_ node: IfExprSyntax) {
      // Must have exactly one condition and no else clause
      guard node.conditions.count == 1, node.elseBody == nil,
        let condition = node.conditions.first?.condition
      else { return }

      // Condition must be a prefix `!` on a .contains() call
      guard let prefixExpr = condition.as(PrefixOperatorExprSyntax.self),
        prefixExpr.operator.text == "!",
        let containsCall = prefixExpr.expression.as(FunctionCallExprSyntax.self),
        let containsMember = containsCall.calledExpression.as(MemberAccessExprSyntax.self),
        containsMember.declName.baseName.text == "contains"
      else { return }

      // Get the receiver name for .contains()
      let receiverText = containsMember.base?.trimmedDescription

      // Skip if receiver is already an optimized collection type
      if let name = receiverText, optimizedVariables.contains(name) {
        return
      }

      // Body must contain a single statement that's .append() on the same receiver
      let bodyStatements = node.body.statements
      guard bodyStatements.count == 1,
        let appendCall = bodyStatements.first?.item
          .as(FunctionCallExprSyntax.self),
        let appendMember = appendCall.calledExpression.as(MemberAccessExprSyntax.self),
        appendMember.declName.baseName.text == "append",
        appendMember.base?.trimmedDescription == receiverText
      else { return }

      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          message: .containsThenAppend,
          confidence: .medium,
          suggestion: "Use OrderedSet for O(1) membership + insertion with stable ordering",
        )
      )
    }

    // MARK: - .sort() after .append() on same receiver

    override func visitPost(_ node: CodeBlockItemListSyntax) {
      let items = Array(node)
      guard items.count >= 2 else { return }

      for i in 1..<items.count {
        guard let sortCall = items[i].item.as(FunctionCallExprSyntax.self),
          let sortMember = sortCall.calledExpression.as(MemberAccessExprSyntax.self),
          sortMember.declName.baseName.text == "sort"
        else { continue }

        let sortReceiver = sortMember.base?.trimmedDescription

        // Skip if receiver is already an optimized collection type
        if let name = sortReceiver, optimizedVariables.contains(name) {
          continue
        }

        // Check if the previous statement is .append() on the same receiver
        guard let prevCall = extractFunctionCall(from: items[i - 1]),
          let prevMember = prevCall.calledExpression.as(MemberAccessExprSyntax.self),
          prevMember.declName.baseName.text == "append",
          prevMember.base?.trimmedDescription == sortReceiver
        else { continue }

        violations.append(
          SyntaxViolation(
            position: sortMember.declName.positionAfterSkippingLeadingTrivia,
            message: .sortAfterAppend,
            confidence: .medium,
            suggestion: "Use Heap for O(log n) insertion that maintains sorted order",
          )
        )
      }
    }

    private func extractFunctionCall(from item: CodeBlockItemSyntax) -> FunctionCallExprSyntax? {
      if let call = item.item.as(FunctionCallExprSyntax.self) {
        return call
      }
      // Handle `let _ = x.append(...)` or `x.append(...)` via sequence expr
      if let seqExpr = item.item.as(SequenceExprSyntax.self) {
        for element in seqExpr.elements {
          if let call = element.as(FunctionCallExprSyntax.self) {
            return call
          }
        }
      }
      return nil
    }
  }
}
