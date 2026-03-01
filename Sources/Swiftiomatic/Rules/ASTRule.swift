/// A rule that recurses into a pre-typechecked AST via SourceKit structure dictionaries
///
/// Conforming rules validate each node whose ``KindType`` matches, walking the
/// ``SourceKitDictionary`` tree depth-first.
protocol SourceKitASTRule: Rule {
  /// The kind of token being recursed over
  associatedtype KindType: RawRepresentable

  /// Validate a single AST node of the expected kind
  ///
  /// - Parameters:
  ///   - file: The file for which to execute the rule.
  ///   - kind: The kind of token being recursed over.
  ///   - dictionary: The dictionary for an AST subset to validate.
  /// - Returns: All style violations to the rule's expectations.
  func validate(file: SwiftSource, kind: KindType, dictionary: SourceKitDictionary)
    -> [RuleViolation]

  /// Extract the ``KindType`` from the specified dictionary
  ///
  /// - Parameters:
  ///   - dictionary: The ``SourceKitDictionary`` representing the source structure
  ///     from which to extract the kind.
  /// - Returns: The kind from the specified dictionary, if one was found.
  func kind(from dictionary: SourceKitDictionary) -> KindType?
}

extension SourceKitASTRule {
  func validate(file: SwiftSource) -> [RuleViolation] {
    validate(file: file, dictionary: file.structureDictionary)
  }

  /// Validate a file by walking the given dictionary subtree depth-first
  ///
  /// - Parameters:
  ///   - file: The file for which to execute the rule.
  ///   - dictionary: The dictionary for an AST subset to validate.
  /// - Returns: All style violations to the rule's expectations.
  func validate(file: SwiftSource, dictionary: SourceKitDictionary) -> [RuleViolation] {
    dictionary.traverseDepthFirst { subDict in
      guard let kind = self.kind(from: subDict) else { return nil }
      return validate(file: file, kind: kind, dictionary: subDict)
    }
  }
}

extension SourceKitASTRule where KindType == SwiftDeclarationKind {
  func kind(from dictionary: SourceKitDictionary) -> KindType? {
    dictionary.declarationKind
  }
}

extension SourceKitASTRule where KindType == ExpressionKind {
  func kind(from dictionary: SourceKitDictionary) -> KindType? {
    dictionary.expressionKind
  }
}

extension SourceKitASTRule where KindType == StatementKind {
  func kind(from dictionary: SourceKitDictionary) -> KindType? {
    dictionary.statementKind
  }
}
