import SwiftiomaticSyntax

struct RedundantBackticksRule {
  static let id = "redundant_backticks"
  static let name = "Redundant Backticks"
  static let summary =
    "Backtick-escaped identifiers that are not keywords in their context are redundant"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      // Plain identifiers without backticks
      Example("let foo = bar"),
      // Raw identifiers with spaces (ref: testNoRemoveBackticksAroundRawIdentifier)
      Example("func `test something`() {}"),
      // Keywords as identifiers (ref: testNoRemoveBackticksAroundKeyword)
      Example("let `let` = foo"),
      Example("let `default`: Int = foo"),
      // Underscore (ref: testNoRemoveBackticksAroundUnderscore)
      Example("func `_`<T>(_ foo: T) -> T { foo }"),
      // Dollar (ref: testNoRemoveBackticksAroundDollar)
      Example("@attached(peer, names: prefixed(`$`))"),
      // self (ref: testNoRemoveBackticksAroundSelf)
      Example("let `self` = foo"),
      // Literal keywords
      Example("let `nil` = fallback"),
      Example("let `true` = 1"),
      Example("let `false` = 0"),
      Example("let `super` = base"),
      // Self in typealias (ref: testNoRemoveBackticksAroundClassSelfInTypealias)
      Example("typealias `Self` = Foo"),
      // Any in enum case (ref: testNoRemoveBackticksAroundAnyProperty)
      Example("enum Foo { case `Any` }"),
      // let as argument — always needs backticks (ref: testNoRemoveBackticksAroundLetArgument)
      Example("func foo(`let`: Foo) {}"),
      // true as argument — needs backticks (ref: testNoRemoveBackticksAroundTrueArgument)
      Example("func foo(`true`: Foo) {}"),
      // Type inside type (ref: testNoRemoveBackticksAroundTypeInsideType)
      Example("struct Foo { enum `Type` {} }"),
      // Type after . (ref: testNoRemoveBackticksAroundTypeProperty)
      Example("var type: Foo.`Type`"),
      // init after . (ref: testNoRemoveBackticksAroundInitPropertyInSwift5)
      Example("let foo: Foo = .`init`"),
      // actor as binding (ref: testNoRemoveBackticksAroundActorProperty)
      Example("let `actor`: Foo"),
      // get in accessor context (ref: testNoRemoveBackticksAroundContextualGet)
      Example("var foo: Int {\n    `get`()\n    return 5\n}"),
      // get in subscript accessor (ref: testNoRemoveBackticksAroundGetInSubscript)
      Example("subscript<T>(_ name: String) -> T where T: Equatable {\n    `get`(name)\n}"),
      // init/deinit/subscript after :: (ref: testNoRemoveBackticksAfterModuleSelectorForInit etc.)
      Example("let x = NASA::`init`"),
      Example("let x = NASA::`deinit`"),
      Example("let x = NASA::`subscript`"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      // Plain identifiers (ref: testRemoveRedundantBackticksInLet)
      Example("let ↓`foo` = bar"),
      Example("func ↓`myFunc`() {}"),
      // Keywords after . (ref: testRemoveBackticksAroundKeywordProperty)
      Example("var type = Foo.↓`default`"),
      Example("var type = Foo.↓`bar`"),
      // Self as return type (ref: testRemoveBackticksAroundClassSelfAsParameterType)
      Example("func foo() -> ↓`Self`"),
      // Self as param type (ref: testRemoveBackticksAroundClassSelfAsReturnType)
      Example("func foo(bar: ↓`Self`) {}"),
      // Any in type position
      Example("let x: ↓`Any` = value"),
      // Type at root level (ref: testRemoveBackticksAroundTypeAtRootLevel)
      Example("enum ↓`Type` {}"),
      // actor as rvalue (ref: testRemoveBackticksAroundActorRvalue)
      Example("let foo = ↓`actor`"),
      // actor as label (ref: testRemoveBackticksAroundActorLabel)
      Example("init(↓`actor`: Foo)"),
      Example("init(↓`actor` foo: Foo)"),
      // get as argument label (ref: testRemoveBackticksAroundGetArgument)
      Example("func foo(↓`get` value: Int) {}"),
      // Keywords after :: (ref: testRemoveBackticksAfterModuleSelector)
      Example("let x = NASA::↓`default`"),
      Example("let x = NASA::↓`let`"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("let ↓`foo` = bar"): Example("let foo = bar"),
      Example("var type = Foo.↓`default`"): Example("var type = Foo.default"),
      Example("func foo() -> ↓`Self`"): Example("func foo() -> Self"),
      Example("enum ↓`Type` {}"): Example("enum Type {}"),
      Example("init(↓`actor`: Foo)"): Example("init(actor: Foo)"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension RedundantBackticksRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantBackticksRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      guard node.hasRedundantBackticks else { return }
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visitAny(_ node: Syntax) -> Syntax? {
      if let result = super.visitAny(node) { return result }
      guard let token = node.as(TokenSyntax.self),
        let bareName = token.redundantBackticksBareName
      else {
        return nil
      }
      numberOfCorrections += 1
      return Syntax(token.with(\.tokenKind, .identifier(bareName)))
    }
  }
}

/// Identifiers that always require backticks — they have special meaning that
/// cannot be overridden regardless of context.
private let backtickAlwaysRequired: Set<String> = ["_", "$", "let", "var"]

/// Literal keywords not in `swiftKeywords` that need backticks as identifiers.
private let literalKeywords: Set<String> = ["self", "super", "nil", "true", "false"]

/// Type-like keywords that are safe only in type annotation positions.
private let typePositionKeywords: Set<String> = ["Self", "Any"]

/// Accessor keywords that need backticks only inside accessor blocks.
private let accessorKeywords: Set<String> = [
  "get", "set", "willSet", "didSet", "init", "_modify",
]

/// Keywords that must keep backticks after `::` module selector.
private let moduleSelectorsNeedBackticks: Set<String> = ["deinit", "init", "subscript"]

extension TokenSyntax {
  /// The bare identifier name if this token has redundant backticks, nil otherwise.
  fileprivate var redundantBackticksBareName: String? {
    guard let bareName = backtickStrippedName,
      bareName.isValidBareIdentifier
    else {
      return nil
    }
    return backtickIsRedundant(for: bareName) ? bareName : nil
  }

  fileprivate var hasRedundantBackticks: Bool {
    redundantBackticksBareName != nil
  }

  /// Determines whether backticks can be safely removed for the given bare name.
  ///
  /// Check order matters: context-specific overrides (after `::`, after `.`)
  /// must run before blanket "always required" checks, because `::` and `.`
  /// make even reserved words like `let`/`var` safe.
  private func backtickIsRedundant(for name: String) -> Bool {
    let prevToken = previousToken(viewMode: .sourceAccurate)
    let prevKind = prevToken?.tokenKind

    // After `::` module selector, most keywords are ordinary identifiers.
    // Must precede backtickAlwaysRequired — `let`/`var` are safe after `::`.
    if prevToken?.parent?.is(ModuleSelectorSyntax.self) == true {
      return !moduleSelectorsNeedBackticks.contains(name)
    }

    // After `.` member access, most identifiers don't need backticks.
    // Must precede backtickAlwaysRequired — `let`/`var` are safe after `.`.
    if prevKind == .period {
      // `init` always needs backticks after `.`
      if name == "init" { return false }
      // `Type` needs backticks after `.` (metatype access)
      if name == "Type" { return false }
      // Everything else (including keywords) is safe after `.`
      return true
    }

    // Identifiers that always need backticks (except after `::` or `.` above)
    if backtickAlwaysRequired.contains(name) {
      return false
    }

    // Literal keywords (self, super, nil, true, false)
    if literalKeywords.contains(name) {
      return false
    }

    // Type-position keywords (Self, Any) — safe only after `:` or `->`
    if typePositionKeywords.contains(name) {
      if prevKind == .colon || prevKind == .arrow {
        return true
      }
      return false
    }

    // `Type` — needs backticks inside type declarations
    if name == "Type" {
      return !isInsideTypeDeclaration
    }

    // Swift keywords need backticks unless in argument position
    if name.isSwiftKeyword {
      return isInArgumentPosition
    }

    // Accessor keywords — only need backticks in accessor context
    if accessorKeywords.contains(name) {
      return !isInAccessorContext
    }

    // `actor` — safe as rvalue or argument label, needs backticks in binding position
    if name == "actor" {
      if isInArgumentPosition { return true }
      if isInRvaluePosition { return true }
      return false
    }

    // Plain identifiers — backticks are always redundant
    return true
  }

  /// Whether this token is a parameter label (argument position) in a call or declaration.
  private var isInArgumentPosition: Bool {
    guard let next = nextToken(viewMode: .sourceAccurate) else { return false }
    // Direct `label:` pattern
    if next.tokenKind == .colon, isInsideParenthesizedContext {
      return true
    }
    // `externalName internalName:` pattern in function parameters
    if case .identifier = next.tokenKind,
      let afterNext = next.nextToken(viewMode: .sourceAccurate),
      afterNext.tokenKind == .colon,
      isInsideParenthesizedContext
    {
      return true
    }
    return false
  }

  /// Whether this token is on the right-hand side of an assignment or initialization.
  private var isInRvaluePosition: Bool {
    guard let prev = previousToken(viewMode: .sourceAccurate) else { return false }
    // After `=` (assignment/initialization)
    if prev.tokenKind == .equal { return true }
    // After `,` in an expression list
    if prev.tokenKind == .comma,
      parent?.parent?.is(LabeledExprListSyntax.self) == true
    {
      return true
    }
    return false
  }

  /// Whether this token is inside parentheses (function call args or parameter list).
  private var isInsideParenthesizedContext: Bool {
    var current: Syntax? = Syntax(self)
    while let node = current {
      if node.is(LabeledExprListSyntax.self)
        || node.is(FunctionParameterListSyntax.self)
        || node.is(EnumCaseParameterListSyntax.self)
      {
        return true
      }
      current = node.parent
    }
    return false
  }

  /// Whether this token is inside an accessor block (get/set/willSet/didSet),
  /// including implicit getter bodies (computed properties without explicit `get { }`).
  private var isInAccessorContext: Bool {
    var current: Syntax? = Syntax(self)
    while let node = current {
      if node.is(AccessorDeclSyntax.self) || node.is(AccessorDeclListSyntax.self)
        || node.is(AccessorBlockSyntax.self)
      {
        return true
      }
      // Stop at function/type boundaries
      if node.is(FunctionDeclSyntax.self) || node.is(ClassDeclSyntax.self)
        || node.is(StructDeclSyntax.self) || node.is(EnumDeclSyntax.self)
      {
        return false
      }
      current = node.parent
    }
    return false
  }

  /// Whether this token is inside a type declaration body (member block).
  ///
  /// Returns `true` only when the token is inside the `{ ... }` body of a
  /// type, not when it is the *name* of the type declaration itself.
  private var isInsideTypeDeclaration: Bool {
    var current: Syntax? = Syntax(self)
    while let node = current {
      if node.is(MemberBlockSyntax.self) {
        return true
      }
      current = node.parent
    }
    return false
  }

  /// If this token is a backtick-escaped identifier, returns the name without backticks.
  private var backtickStrippedName: String? {
    guard case .identifier(let name) = tokenKind,
      name.hasPrefix("`"), name.hasSuffix("`")
    else {
      return nil
    }
    return String(name.dropFirst().dropLast())
  }
}

extension String {
  /// Whether this string is a valid Swift identifier without backtick escaping.
  fileprivate var isValidBareIdentifier: Bool {
    guard let first = unicodeScalars.first,
      first == "_" || first.properties.isXIDStart
    else {
      return false
    }
    return unicodeScalars.dropFirst().allSatisfy(\.properties.isXIDContinue)
  }
}
