import SwiftiomaticSyntax

struct RedundantTypeAnnotationRule {
  static let id = "redundant_type_annotation"
  static let name = "Redundant Type Annotation"
  static let summary = "Variables should not have redundant type annotation"
  static let isCorrectable = true
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("var url = URL()"),
      Example("var url: CustomStringConvertible = URL()"),
      Example("var one: Int = 1, two: Int = 2, three: Int"),
      Example("guard let url = URL() else { return }"),
      Example("if let url = URL() { return }"),
      Example("let alphanumerics = CharacterSet.alphanumerics"),
      Example("var set: Set<Int> = Set([])"),
      Example("var set: Set<Int> = Set.init([])"),
      Example("var set = Set<Int>([])"),
      Example("var set = Set<Int>.init([])"),
      Example("guard var set: Set<Int> = Set([]) else { return }"),
      Example("if var set: Set<Int> = Set.init([]) { return }"),
      Example("guard var set = Set<Int>([]) else { return }"),
      Example("if var set = Set<Int>.init([]) { return }"),
      Example("var one: A<T> = B()"),
      Example("var one: A = B<T>()"),
      Example("var one: A<T> = B<T>()"),
      Example("let a = A.b.c.d"),
      Example("let a: B = A.b.c.d"),
      Example(
        """
        enum Direction {
            case up
            case down
        }

        var direction: Direction = .up
        """,
      ),
      Example(
        """
        enum Direction {
            case up
            case down
        }

        var direction = Direction.up
        """,
      ),
      Example(
        "@IgnoreMe var a: Int = Int(5)",
        configuration: ["ignore_attributes": ["IgnoreMe"]],
      ),
      Example(
        """
        var a: Int {
            @IgnoreMe let i: Int = Int(1)
            return i
        }
        """, configuration: ["ignore_attributes": ["IgnoreMe"]],
      ),
      Example("var bol: Bool = true"),
      Example("var dbl: Double = 0.0"),
      Example("var int: Int = 0"),
      Example("var str: String = \"str\""),
      Example(
        """
        struct Foo {
            var url: URL = URL()
            let myVar: Int? = 0, s: String = ""
        }
        """, configuration: ["ignore_properties": true],
      ),
      Example(  // @Model classes — SwiftData requires explicit type annotations
        """
        @Model
        class User {
            var name: String = String()
        }
        """
      ),
      Example(  // ternary — type annotation needed for disambiguation
        "var status: Status = condition ? .active : .inactive"
      ),
      Example(  // inferLocalsOnly — type member keeps explicit annotation
        """
        struct Foo {
            var url: URL = URL()
        }
        """,
        configuration: ["infer_locals_only": true],
      ),
      Example(  // inferLocalsOnly — global keeps explicit annotation
        "var url: URL = URL()",
        configuration: ["infer_locals_only": true],
      ),
      Example(  // Set with array literal — element type matches
        "var set: Set = [1, 2, 3]"
      ),
      Example(  // Set with array literal — mixed element types
        "var set: Set<Any> = [1, \"a\"]"
      ),
      Example(  // Set with non-literal elements
        "var set: Set<Int> = [a, b]"
      ),
      Example(  // if expression — different types in branches
        """
        let x: Any = if condition {
            Int(1)
        } else {
            String("a")
        }
        """
      ),
      Example(  // if expression — incomplete (no else)
        """
        let x: Foo = if condition {
            Foo()
        }
        """,
        isExcludedFromDocumentation: true,
      ),
      Example(  // switch — different types per case
        """
        let x: Any = switch value {
        case .a: Int(1)
        case .b: String("b")
        }
        """
      ),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("var url↓:URL=URL()"),
      Example("var url↓:URL = URL(string: \"\")"),
      Example("var url↓: URL = URL()"),
      Example("let url↓: URL = URL()"),
      Example("lazy var url↓: URL = URL()"),
      Example("let url↓: URL = URL()!"),
      Example("var one: Int = 1, two↓: Int = Int(5), three: Int"),
      Example("guard let url↓: URL = URL() else { return }"),
      Example("if let url↓: URL = URL() { return }"),
      Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"),
      Example("var set↓: Set<Int> = Set<Int>([])"),
      Example("var set↓: Set<Int> = Set<Int>.init([])"),
      Example("var set↓: Set = Set<Int>([])"),
      Example("var set↓: Set = Set<Int>.init([])"),
      Example("guard var set↓: Set = Set<Int>([]) else { return }"),
      Example("if var set↓: Set = Set<Int>.init([]) { return }"),
      Example("guard var set↓: Set<Int> = Set<Int>([]) else { return }"),
      Example("if var set↓: Set<Int> = Set<Int>.init([]) { return }"),
      Example("var set↓: Set = Set<Int>([]), otherSet: Set<Int>"),
      Example("var num↓: Int = Int.random(0..<10)"),
      Example("let a↓: A = A.b.c.d"),
      Example("let a↓: A = A.f().b"),
      Example(
        """
        class ViewController: UIViewController {
          func someMethod() {
            let myVar↓: Int = Int(5)
          }
        }
        """,
      ),
      Example(
        """
        class ViewController: UIViewController {
          func someMethod() {
            let myVar↓: Int = Int(5)
          }
        }
        """, configuration: ["ignore_properties": true],
      ),
      Example("let a↓: [Int] = [Int]()"),
      Example("let a↓: A.B = A.B()"),
      Example(
        """
        enum Direction {
            case up
            case down
        }

        var direction↓: Direction = Direction.up
        """,
      ),
      Example(
        "@DontIgnoreMe var a↓: Int = Int(5)",
        configuration: ["ignore_attributes": ["IgnoreMe"]],
      ),
      Example(
        """
        @IgnoreMe
        var a: Int {
            let i↓: Int = Int(1)
            return i
        }
        """, configuration: ["ignore_attributes": ["IgnoreMe"]],
      ),
      Example(  // inferLocalsOnly — local variable still flagged
        """
        func foo() {
            let myVar↓: Int = Int(5)
        }
        """,
        configuration: ["infer_locals_only": true],
      ),
      Example(
        "var bol↓: Bool = true",
        configuration: ["consider_default_literal_types_redundant": true],
      ),
      Example(
        "var dbl↓: Double = 0.0",
        configuration: ["consider_default_literal_types_redundant": true],
      ),
      Example(
        "var int↓: Int = 0",
        configuration: ["consider_default_literal_types_redundant": true],
      ),
      Example(
        "var str↓: String = \"str\"",
        configuration: ["consider_default_literal_types_redundant": true],
      ),
      Example(  // Set with array literal — inferable generic argument
        "var set: Set↓<Int> = [1, 2, 3]"
      ),
      Example(  // Set with string literal — inferable generic argument
        "var set: Set↓<String> = [\"a\", \"b\"]"
      ),
      Example(  // if expression — all branches match type
        """
        let foo↓: Foo = if condition {
            Foo("a")
        } else {
            Foo("b")
        }
        """
      ),
      Example(  // if/else if/else — all branches match
        """
        let foo↓: Foo = if a {
            Foo("a")
        } else if b {
            Foo("b")
        } else {
            Foo("c")
        }
        """
      ),
      Example(  // switch — all cases match type
        """
        let foo↓: Foo = switch value {
        case .a: Foo("a")
        case .b: Foo("b")
        }
        """
      ),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("var url↓: URL = URL()"): Example("var url = URL()"),
      Example("let url↓: URL = URL()"): Example("let url = URL()"),
      Example("var one: Int = 1, two↓: Int = Int(5), three: Int"):
        Example("var one: Int = 1, two = Int(5), three: Int"),
      Example("guard let url↓: URL = URL() else { return }"):
        Example("guard let url = URL() else { return }"),
      Example("if let url↓: URL = URL() { return }"):
        Example("if let url = URL() { return }"),
      Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"):
        Example("let alphanumerics = CharacterSet.alphanumerics"),
      Example("var set↓: Set<Int> = Set<Int>([])"):
        Example("var set = Set<Int>([])"),
      Example("var set↓: Set<Int> = Set<Int>.init([])"):
        Example("var set = Set<Int>.init([])"),
      Example("var set↓: Set = Set<Int>([])"):
        Example("var set = Set<Int>([])"),
      Example("var set↓: Set = Set<Int>.init([])"):
        Example("var set = Set<Int>.init([])"),
      Example("guard var set↓: Set<Int> = Set<Int>([]) else { return }"):
        Example("guard var set = Set<Int>([]) else { return }"),
      Example("if var set↓: Set<Int> = Set<Int>.init([]) { return }"):
        Example("if var set = Set<Int>.init([]) { return }"),
      Example("var set↓: Set = Set<Int>([]), otherSet: Set<Int>"):
        Example("var set = Set<Int>([]), otherSet: Set<Int>"),
      Example("let a↓: A = A.b.c.d"):
        Example("let a = A.b.c.d"),
      Example(
        """
        class ViewController: UIViewController {
          func someMethod() {
            let myVar↓: Int = Int(5)
          }
        }
        """,
      ):
        Example(
          """
          class ViewController: UIViewController {
            func someMethod() {
              let myVar = Int(5)
            }
          }
          """,
        ),
      Example("var num: Int = Int.random(0..<10)"): Example("var num = Int.random(0..<10)"),
      Example(
        """
        @IgnoreMe
        var a: Int {
            let i↓: Int = Int(1)
            return i
        }
        """, configuration: ["ignore_attributes": ["IgnoreMe"]],
      ):
        Example(
          """
          @IgnoreMe
          var a: Int {
              let i = Int(1)
              return i
          }
          """,
        ),
      Example(
        "var bol: Bool = true",
        configuration: ["consider_default_literal_types_redundant": true],
      ):
        Example("var bol = true"),
      Example(
        "var dbl: Double = 0.0",
        configuration: ["consider_default_literal_types_redundant": true],
      ):
        Example("var dbl = 0.0"),
      Example(
        "var int: Int = 0",
        configuration: ["consider_default_literal_types_redundant": true],
      ):
        Example("var int = 0"),
      Example(
        "var str: String = \"str\"",
        configuration: ["consider_default_literal_types_redundant": true],
      ):
        Example("var str = \"str\""),
      // Set generic argument correction
      Example("var set: Set↓<Int> = [1, 2, 3]"):
        Example("var set: Set = [1, 2, 3]"),
      // if expression correction
      Example(
        """
        let foo↓: Foo = if condition {
            Foo("a")
        } else {
            Foo("b")
        }
        """
      ):
        Example(
          """
          let foo = if condition {
              Foo("a")
          } else {
              Foo("b")
          }
          """
        ),
    ]
  }

  var options = RedundantTypeAnnotationOptions()
}

extension RedundantTypeAnnotationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantTypeAnnotationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: PatternBindingSyntax) {
      if let varDecl = node.parent?.parent?.as(VariableDeclSyntax.self),
        !configuration.shouldSkipRuleCheck(for: varDecl),
        !varDecl.isInModelType,
        let typeAnnotation = node.typeAnnotation,
        let initializer = node.initializer?.value
      {
        collectViolation(forType: typeAnnotation, withInitializer: initializer)
      }
    }

    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      if let typeAnnotation = node.typeAnnotation,
        let initializer = node.initializer?.value
      {
        collectViolation(forType: typeAnnotation, withInitializer: initializer)
      }
    }

    private func collectViolation(
      forType type: TypeAnnotationSyntax, withInitializer initializer: ExprSyntax,
    ) {
      let validateLiterals = configuration.considerDefaultLiteralTypesRedundant
      let isLiteralRedundant =
        validateLiterals
        && initializer
          .hasRedundant(literalType: type.type)

      // Check if/switch expression branches (SE-0380)
      let isBranchRedundant: Bool
      if let ifExpr = initializer.as(IfExprSyntax.self) {
        isBranchRedundant = ifExpr.allBranchExpressionsMatch(type: type.type)
      } else if let switchExpr = initializer.as(SwitchExprSyntax.self) {
        isBranchRedundant = switchExpr.allCaseExpressionsMatch(type: type.type)
      } else {
        isBranchRedundant = false
      }

      guard isLiteralRedundant || isBranchRedundant || initializer.hasRedundant(type: type.type)
      else {
        // Check for Set<T> with array literal where T is inferable
        collectSetGenericArgViolation(forType: type, withInitializer: initializer)
        return
      }
      violations.append(
        SyntaxViolation(
          position: type.positionAfterSkippingLeadingTrivia,
          correction: .init(
            start: type.position,
            end: type.endPositionBeforeTrailingTrivia,
            replacement: "",
          ),
          highlights: [Syntax(type.type)],
          notes: [
            .init(
              position: initializer.positionAfterSkippingLeadingTrivia,
              message: "type is inferred from this initializer"
            ),
          ],
        ),
      )
    }

    /// Detects `Set<T> = [literals]` where `T` is inferable from the array literal elements,
    /// removing only the generic argument clause (`<T>`) rather than the entire type annotation.
    private func collectSetGenericArgViolation(
      forType type: TypeAnnotationSyntax, withInitializer initializer: ExprSyntax,
    ) {
      guard let identifierType = type.type.as(IdentifierTypeSyntax.self),
        identifierType.name.text == "Set",
        let genericArgs = identifierType.genericArgumentClause,
        genericArgs.arguments.count == 1,
        let genericArg = genericArgs.arguments.first,
        let arrayExpr = initializer.as(ArrayExprSyntax.self),
        !arrayExpr.elements.isEmpty
      else { return }

      let expectedType = genericArg.argument.trimmedDescription
      let allMatch = arrayExpr.elements.allSatisfy { element in
        element.expression.kind.compilerInferredLiteralType == expectedType
      }
      guard allMatch else { return }

      violations.append(
        at: genericArgs.positionAfterSkippingLeadingTrivia,
        correction: .init(
          start: genericArgs.position,
          end: genericArgs.endPositionBeforeTrailingTrivia,
          replacement: "",
        ),
      )
    }
  }
}

extension ExprSyntax {
  /// An expression can represent an access to an identifier in one or another way depending on the exact underlying
  /// expression type. E.g. the expression `A` accesses `A` while `f()` accesses `f` and `a.b.c` accesses `a` in the
  /// sense of this property. In the context of this rule, `Set<Int>()` accesses `Set` as well as `Set<Int>`.
  private var accessedNames: [String] {
    if let declRef = `as`(DeclReferenceExprSyntax.self) {
      [declRef.trimmedDescription]
    } else if let memberAccess = `as`(MemberAccessExprSyntax.self) {
      (memberAccess.base?.accessedNames ?? []) + [memberAccess.trimmedDescription]
    } else if let genericSpecialization = `as`(GenericSpecializationExprSyntax.self) {
      [genericSpecialization.trimmedDescription]
        + genericSpecialization.expression
        .accessedNames
    } else if let call = `as`(FunctionCallExprSyntax.self) {
      call.calledExpression.accessedNames
    } else if let arrayExpr = `as`(ArrayExprSyntax.self) {
      [arrayExpr.trimmedDescription]
    } else {
      []
    }
  }

  fileprivate func hasRedundant(literalType type: TypeSyntax) -> Bool {
    type.trimmedDescription == kind.compilerInferredLiteralType
  }

  fileprivate func hasRedundant(type: TypeSyntax) -> Bool {
    `as`(ForceUnwrapExprSyntax.self)?.expression.hasRedundant(type: type)
      ?? accessedNames.contains(type.trimmedDescription)
  }
}

extension IfExprSyntax {
  /// Returns `true` if every branch of this if/else if/else chain has a last expression
  /// that matches the given type annotation.
  fileprivate func allBranchExpressionsMatch(type: TypeSyntax) -> Bool {
    // The "then" branch must match
    guard let thenExpr = body.lastExpression, thenExpr.hasRedundant(type: type) else {
      return false
    }
    // Must have an else branch (otherwise it's not a complete expression)
    guard let elseBody else { return false }

    switch elseBody {
    case .ifExpr(let nestedIf):
      return nestedIf.allBranchExpressionsMatch(type: type)
    case .codeBlock(let codeBlock):
      guard let elseExpr = codeBlock.lastExpression, elseExpr.hasRedundant(type: type) else {
        return false
      }
      return true
    }
  }
}

extension SwitchExprSyntax {
  /// Returns `true` if every case of this switch expression has a last expression
  /// that matches the given type annotation.
  fileprivate func allCaseExpressionsMatch(type: TypeSyntax) -> Bool {
    let switchCases = cases.compactMap { $0.as(SwitchCaseSyntax.self) }
    guard !switchCases.isEmpty else { return false }

    return switchCases.allSatisfy { switchCase in
      guard let lastExpr = switchCase.statements.lastExpression,
        lastExpr.hasRedundant(type: type)
      else {
        return false
      }
      return true
    }
  }
}

extension CodeBlockSyntax {
  /// The last expression in this code block, if the last item is an expression.
  fileprivate var lastExpression: ExprSyntax? {
    statements.lastExpression
  }
}

extension CodeBlockItemListSyntax {
  /// The last expression in this statement list, if the last item is an expression.
  fileprivate var lastExpression: ExprSyntax? {
    guard let lastItem = last?.item else { return nil }
    return lastItem.as(ExprSyntax.self)
      ?? lastItem.as(ExpressionStmtSyntax.self)?.expression
  }
}

extension SyntaxKind {
  fileprivate var compilerInferredLiteralType: String? {
    switch self {
    case .booleanLiteralExpr:
      "Bool"
    case .floatLiteralExpr:
      "Double"
    case .integerLiteralExpr:
      "Int"
    case .stringLiteralExpr:
      "String"
    default:
      nil
    }
  }
}

extension RedundantTypeAnnotationOptions {
  func shouldSkipRuleCheck(for varDecl: VariableDeclSyntax) -> Bool {
    if ignoreAttributes.contains(where: { varDecl.attributes.contains(attributeNamed: $0) }) {
      return true
    }
    if ignoreProperties && varDecl.parent?.is(MemberBlockItemSyntax.self) == true {
      return true
    }
    if inferLocalsOnly && !varDecl.isInLocalScope {
      return true
    }
    return false
  }
}

extension VariableDeclSyntax {
  /// Whether this variable is in a local scope (function body, closure, loop) vs global or type member
  fileprivate var isInLocalScope: Bool {
    if parent?.is(MemberBlockItemSyntax.self) == true { return false }
    var current: Syntax? = parent
    while let node = current {
      if node.is(CodeBlockSyntax.self) { return true }
      if node.is(SourceFileSyntax.self) { return false }
      current = node.parent
    }
    return false
  }

  /// Whether this is a stored property inside a @Model class (SwiftData requires explicit types)
  fileprivate var isInModelType: Bool {
    guard parent?.is(MemberBlockItemSyntax.self) == true else { return false }
    var current: Syntax? = parent
    while let node = current {
      if let decl = node.as(ClassDeclSyntax.self) {
        return decl.attributes.contains(attributeNamed: "Model")
      }
      if node.is(StructDeclSyntax.self) || node.is(EnumDeclSyntax.self)
        || node.is(ActorDeclSyntax.self)
      {
        return false
      }
      current = node.parent
    }
    return false
  }
}
