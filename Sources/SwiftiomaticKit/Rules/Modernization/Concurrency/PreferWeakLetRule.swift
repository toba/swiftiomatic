import SwiftiomaticSyntax

struct PreferWeakLetRule {
  static let id = "prefer_weak_let"
  static let name = "Prefer Weak Let"
  static let summary = "Prefer weak let over weak var when the reference is never reassigned"
  static let scope: Scope = .lint
  static let isOptIn = false
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example(
        """
        class Foo {
            weak var delegate: AnyObject? {
                didSet { print("changed") }
            }
        }
        """),
      Example(
        """
        class Foo {
            func bar() {
                weak var ref: AnyObject? = self
                ref = nil
            }
        }
        """),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example(
        """
        class Foo {
            ↓weak var delegate: AnyObject?
        }
        """),
      Example(
        """
        class Foo {
            func bar() {
                ↓weak var ref: AnyObject? = self
                print(ref as Any)
            }
        }
        """),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example(
        """
        class Foo {
            ↓weak var delegate: AnyObject?
        }
        """): Example(
        """
        class Foo {
            weak let delegate: AnyObject?
        }
        """),
      Example(
        """
        class Foo {
            func bar() {
                ↓weak var ref: AnyObject? = self
                print(ref as Any)
            }
        }
        """): Example(
        """
        class Foo {
            func bar() {
                weak let ref: AnyObject? = self
                print(ref as Any)
            }
        }
        """),
    ]
  }

  static let relatedRuleIDs = ["swift_modernization"]

  var options = SeverityOption<Self>(.warning)
}

extension PreferWeakLetRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferWeakLetRule: Rule {}

extension PreferWeakLetRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      let hasWeak = node.modifiers.contains { $0.name.text == "weak" }
      let hasAccessors = node.bindings.contains { binding in
        binding.accessorBlock != nil
      }
      guard hasWeak, node.bindingSpecifier.tokenKind == .keyword(.var), !hasAccessors else {
        return
      }

      let bindingName = node.bindings.first?.pattern.trimmedDescription ?? "unknown"

      guard !isReassigned(bindingName, from: node) else {
        // Variable is genuinely reassigned — needs var
        return
      }

      let varToken = node.bindingSpecifier
      let correction = SyntaxViolation.Correction(
        start: varToken.positionAfterSkippingLeadingTrivia,
        end: varToken.endPositionBeforeTrailingTrivia,
        replacement: "let",
      )
      violations.append(
        SyntaxViolation(
          position: node.positionAfterSkippingLeadingTrivia,
          reason:
            "weak var '\(bindingName)' is never reassigned — use weak let (SE-0481)",
          severity: configuration.severity,
          correction: correction,
          confidence: .high,
          suggestion: "weak let \(bindingName)",
        ),
      )
    }

    private func isReassigned(_ name: String, from node: VariableDeclSyntax) -> Bool {
      let scope = containingScope(of: Syntax(node))
      let declRange = node.position..<node.endPosition
      return searchForAssignment(named: name, in: scope, excluding: declRange)
    }

    private func searchForAssignment(
      named name: String, in node: Syntax,
      excluding declRange: Range<AbsolutePosition>,
    ) -> Bool {
      // Skip the declaration itself entirely
      if declRange.contains(node.position), node.endPosition <= declRange.upperBound {
        return false
      }

      // Check SequenceExprSyntax (how SwiftSyntax parses assignments in this version)
      if let seqExpr = node.as(SequenceExprSyntax.self) {
        let elements = Array(seqExpr.elements)
        if elements.count >= 2,
          let lhs = elements.first?.as(DeclReferenceExprSyntax.self),
          lhs.baseName.text == name,
          elements.dropFirst().first?.is(AssignmentExprSyntax.self) == true
        {
          return true
        }
      }

      // Check InfixOperatorExprSyntax (for compound assignments)
      if let infixExpr = node.as(InfixOperatorExprSyntax.self),
        let lhs = infixExpr.leftOperand.as(DeclReferenceExprSyntax.self),
        lhs.baseName.text == name
      {
        if infixExpr.operator.is(AssignmentExprSyntax.self) { return true }

        if let binOp = infixExpr.operator.as(BinaryOperatorExprSyntax.self) {
          let text = binOp.operator.text
          if text == "+=" || text == "-=" || text == "*=" || text == "/="
            || text == "%=" || text == "&=" || text == "|=" || text == "^="
            || text == "<<=" || text == ">>="
          {
            return true
          }
        }
      }

      // Recurse into children
      for child in node.children(viewMode: .sourceAccurate) {
        if searchForAssignment(named: name, in: child, excluding: declRange) {
          return true
        }
      }
      return false
    }

    private func containingScope(of node: Syntax) -> Syntax {
      var current = node.parent
      while let parent = current {
        if parent.is(CodeBlockSyntax.self)
          || parent.is(MemberBlockSyntax.self)
          || parent.is(SourceFileSyntax.self)
        {
          return parent
        }
        current = parent.parent
      }
      return node.root
    }
  }
}
