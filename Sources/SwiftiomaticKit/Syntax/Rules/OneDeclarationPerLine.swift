//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Each enum case with associated values or a raw value should appear in its own case declaration,
/// and each variable declaration (except tuple destructuring) should declare only one variable.
///
/// Lint: If a single `case` declaration declares multiple cases where any has associated values or
///       raw values, or if a variable declaration declares multiple variables, a lint error is
///       raised.
///
/// Format: Case declarations with associated values or raw values will be moved to their own case
///         declarations. Variable declarations with multiple bindings will be split into individual
///         declarations.
final class OneDeclarationPerLine: RewriteSyntaxRule {

  // MARK: - Enum cases

  /// A state machine that collects case elements encountered during visitation and allows new case
  /// declarations to be created with those elements.
  private struct CaseElementCollector {

    /// The case declaration used as the source from which additional new declarations will be
    /// created; thus, all new cases will share the same attributes and modifiers as the basis.
    private(set) var basis: EnumCaseDeclSyntax

    /// Case elements collected so far.
    private var elements = [EnumCaseElementSyntax]()

    /// Indicates whether the full leading trivia of basis case declaration should be preserved by
    /// the next case declaration that will be created by copying the basis declaration.
    ///
    /// This is true for the first case (to preserve any leading comments on the original case
    /// declaration) and false for all subsequent cases (so that we don't repeat those comments).
    private var shouldKeepLeadingTrivia = true

    /// Creates a new case element collector based on the given case declaration.
    init(basedOn basis: EnumCaseDeclSyntax) {
      self.basis = basis
    }

    /// Adds a new case element to the collector.
    mutating func addElement(_ element: EnumCaseElementSyntax) {
      elements.append(element)
    }

    /// Creates a new case declaration with the elements collected so far, then resets the internal
    /// state to start a new empty declaration again.
    ///
    /// This will return nil if there are no elements collected since the last time this was called
    /// (or the collector was created).
    mutating func makeCaseDeclAndReset() -> EnumCaseDeclSyntax? {
      guard !elements.isEmpty else { return nil }

      // Remove the trailing comma on the final element, if there was one.
      elements[elements.count - 1].trailingComma = nil

      defer { elements.removeAll() }
      return makeCaseDeclFromBasis(elements: elements)
    }

    /// Creates and returns a new `EnumCaseDeclSyntax` with the given elements, based on the current
    /// basis declaration, and updates the comment preserving state if needed.
    mutating func makeCaseDeclFromBasis(elements: [EnumCaseElementSyntax]) -> EnumCaseDeclSyntax {
      var caseDecl = basis
      caseDecl.elements = EnumCaseElementListSyntax(elements)

      if shouldKeepLeadingTrivia {
        shouldKeepLeadingTrivia = false

        // We don't bother preserving any indentation because the pretty printer will fix that up.
        // All we need to do here is ensure that there is a newline.
        basis.leadingTrivia = Trivia.newlines(1)
      }

      return caseDecl
    }
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    var newMembers: [MemberBlockItemSyntax] = []

    for member in node.memberBlock.members {
      // If it's not a case declaration, or it's a case declaration with only one element, leave it
      // alone.
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self), caseDecl.elements.count > 1 else {
        newMembers.append(member)
        continue
      }

      var collector = CaseElementCollector(basedOn: caseDecl)

      // Collect the elements of the case declaration until we see one that has either an associated
      // value or a raw value.
      for element in caseDecl.elements {
        if element.parameterClause != nil || element.rawValue != nil {
          // Once we reach one of these, we need to write out the ones we've collected so far, then
          // emit a separate case declaration with the associated/raw value element.
          diagnose(.moveAssociatedOrRawValueCase(name: element.name.text), on: element)

          if let caseDeclForCollectedElements = collector.makeCaseDeclAndReset() {
            var newMember = member
            newMember.decl = DeclSyntax(caseDeclForCollectedElements)
            newMembers.append(newMember)
          }

          var basisElement = element
          basisElement.trailingComma = nil
          let separatedCaseDecl = collector.makeCaseDeclFromBasis(elements: [basisElement])

          var newMember = member
          newMember.decl = DeclSyntax(separatedCaseDecl)
          newMembers.append(newMember)
        } else {
          collector.addElement(element)
        }
      }

      // Make sure to emit any trailing collected elements.
      if let caseDeclForCollectedElements = collector.makeCaseDeclAndReset() {
        var newMember = member
        newMember.decl = DeclSyntax(caseDeclForCollectedElements)
        newMembers.append(newMember)
      }
    }

    var result = node
    result.memberBlock.members = MemberBlockItemListSyntax(newMembers)
    return DeclSyntax(result)
  }

  // MARK: - Variable declarations

  override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    guard node.contains(where: codeBlockItemHasMultipleVariableBindings) else {
      return super.visit(node)
    }

    var newItems = [CodeBlockItemSyntax]()
    for codeBlockItem in node {
      guard let varDecl = codeBlockItem.item.as(VariableDeclSyntax.self),
        varDecl.bindings.count > 1
      else {
        // It's not a variable declaration with multiple bindings, so visit it
        // recursively (in case it's something that contains bindings that need
        // to be split) but otherwise do nothing.
        let newItem = super.visit(codeBlockItem)
        newItems.append(newItem)
        continue
      }

      diagnose(.onlyOneVariableDeclaration(specifier: varDecl.bindingSpecifier.text), on: varDecl)

      // Visit the decl recursively to make sure nested code block items in the
      // bindings (for example, an initializer expression that contains a
      // closure expression) are transformed first before we rewrite the decl
      // itself.
      let visitedDecl = super.visit(varDecl).as(VariableDeclSyntax.self)!
      var splitter = VariableDeclSplitter {
        CodeBlockItemSyntax(
          item: .decl(DeclSyntax($0)),
          semicolon: nil
        )
      }
      newItems.append(contentsOf: splitter.nodes(bySplitting: visitedDecl))
    }

    return CodeBlockItemListSyntax(newItems)
  }

  /// Returns true if the given `CodeBlockItemSyntax` contains a `let` or `var`
  /// declaration with multiple bindings.
  private func codeBlockItemHasMultipleVariableBindings(
    _ node: CodeBlockItemSyntax
  ) -> Bool {
    if let varDecl = node.item.as(VariableDeclSyntax.self),
      varDecl.bindings.count > 1
    {
      return true
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static func moveAssociatedOrRawValueCase(name: String) -> Finding.Message {
    "move '\(name)' to its own 'case' declaration"
  }

  fileprivate static func onlyOneVariableDeclaration(specifier: String) -> Finding.Message {
    "split this variable declaration to introduce only one variable per '\(specifier)'"
  }
}

/// Splits a variable declaration with multiple bindings into individual
/// declarations.
///
/// Swift's grammar allows each identifier in a variable declaration to have a
/// type annotation, an initializer expression, both, or neither. Stricter
/// checks occur after parsing, however; a lone identifier may only be followed
/// by zero or more other lone identifiers and then an identifier with *only* a
/// type annotation (and the type annotation is applied to all of them). If we
/// have something else, we should handle them gracefully (i.e., not destroy
/// them) but we don't need to try to fix them since they didn't compile in the
/// first place so we can't guess what the user intended.
///
/// So, this algorithm works by scanning forward and collecting lone identifiers
/// in a queue until we reach a binding that has an initializer or a type
/// annotation. If we see a type annotation (without an initializer), we can
/// create individual variable declarations for each entry in the queue by
/// projecting that type annotation onto each of them. If we reach a case that
/// isn't valid, we just flush the queue contents as a single declaration, to
/// effectively preserve what the user originally had.
private struct VariableDeclSplitter<Node: SyntaxProtocol> {
  /// A function that takes a `VariableDeclSyntax` and returns a new node, such
  /// as a `CodeBlockItemSyntax`, that wraps it.
  private let generator: (VariableDeclSyntax) -> Node

  /// Bindings that have been collected so far and the trivia that preceded them.
  private var bindingQueue = [(PatternBindingSyntax, Trivia)]()

  /// The variable declaration being split.
  ///
  /// This is an implicitly-unwrapped optional because it isn't initialized
  /// until `nodes(bySplitting:)` is called.
  private var varDecl: VariableDeclSyntax!

  /// The list of nodes generated by splitting the variable declaration into
  /// individual bindings.
  private var nodes = [Node]()

  /// Tracks whether the trivia of `varDecl` has already been fixed up for nodes
  /// after the first.
  private var fixedUpTrivia = false

  /// Creates a new variable declaration splitter.
  ///
  /// - Parameter generator: A function that takes a `VariableDeclSyntax` and
  ///   returns a new node, such as a `CodeBlockItemSyntax`, that wraps it.
  init(generator: @escaping (VariableDeclSyntax) -> Node) {
    self.generator = generator
  }

  /// Returns an array of nodes generated by splitting the given variable
  /// declaration into individual bindings.
  mutating func nodes(bySplitting varDecl: VariableDeclSyntax) -> [Node] {
    self.varDecl = varDecl
    self.nodes = []

    // We keep track of trivia that precedes each binding (which is reflected as trailing trivia
    // on the previous token) so that we can reassociate it if we flush the bindings out as
    // individual variable decls. This means that we can rewrite `let /*a*/ a, /*b*/ b: Int` as
    // `let /*a*/ a: Int; let /*b*/ b: Int`, for example.
    var precedingTrivia = varDecl.bindingSpecifier.trailingTrivia

    for binding in varDecl.bindings {
      if binding.initializer != nil {
        // If this is the only initializer in the queue so far, that's ok. If
        // it's an initializer following other un-flushed lone identifier
        // bindings, that's not valid Swift. But in either case, we'll flush
        // them as a single decl.
        var newBinding = binding
        newBinding.trailingComma = nil
        bindingQueue.append((newBinding, precedingTrivia))
        flushRemaining()
      } else if let typeAnnotation = binding.typeAnnotation {
        bindingQueue.append((binding, precedingTrivia))
        flushIndividually(typeAnnotation: typeAnnotation)
      } else {
        bindingQueue.append((binding, precedingTrivia))
      }
      precedingTrivia = binding.trailingComma?.trailingTrivia ?? []
    }
    flushRemaining()

    return nodes
  }

  /// Replaces the original variable declaration with a copy of itself with
  /// updates trivia appropriate for subsequent declarations inserted by the
  /// rule.
  private mutating func fixOriginalVarDeclTrivia() {
    guard !fixedUpTrivia else { return }

    // We intentionally don't try to infer the indentation for subsequent
    // lines because the pretty printer will re-indent them correctly; we just
    // need to ensure that a newline is inserted before new decls.
    varDecl.leadingTrivia = [.newlines(1)]
    fixedUpTrivia = true
  }

  /// Flushes any remaining bindings as a single variable declaration.
  private mutating func flushRemaining() {
    guard !bindingQueue.isEmpty else { return }

    var newDecl = varDecl!
    newDecl.bindings = PatternBindingListSyntax(bindingQueue.map(\.0))
    nodes.append(generator(newDecl))

    fixOriginalVarDeclTrivia()

    bindingQueue = []
  }

  /// Flushes any remaining bindings as individual variable declarations where
  /// each has the given type annotation.
  private mutating func flushIndividually(
    typeAnnotation: TypeAnnotationSyntax
  ) {
    assert(!bindingQueue.isEmpty)

    for (binding, trailingTrivia) in bindingQueue {
      assert(binding.initializer == nil)

      var newBinding = binding
      newBinding.typeAnnotation = typeAnnotation
      newBinding.trailingComma = nil

      var newDecl = varDecl!
      newDecl.bindingSpecifier.trailingTrivia = trailingTrivia
      newDecl.bindings = PatternBindingListSyntax([newBinding])
      nodes.append(generator(newDecl))

      fixOriginalVarDeclTrivia()
    }

    bindingQueue = []
  }
}
