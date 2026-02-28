/// Marker protocol used to check whether a rule is collectable.
protocol CollectingRuleMarker: Rule {}

/// A rule that requires knowledge of all other files being linted.
protocol CollectingRule: CollectingRuleMarker {
  /// The kind of information to collect for each file being linted for this rule.
  associatedtype FileInfo

  /// Collects information for the specified file, to be analyzed by a `CollectedLinter`.
  ///
  /// - parameter file:              The file for which to collect info.
  /// - parameter compilerArguments: The compiler arguments needed to compile this file.
  ///
  /// - returns: The collected file information.
  func collectInfo(for file: SwiftSource, compilerArguments: [String]) -> FileInfo

  /// Collects information for the specified file, to be analyzed by a `CollectedLinter`.
  ///
  /// - parameter file: The file for which to collect info.
  ///
  /// - returns: The collected file information.
  func collectInfo(for file: SwiftSource) -> FileInfo

  /// Executes the rule on a file after collecting file info for all files and returns any violations to the rule's
  /// expectations.
  ///
  /// - parameter file:              The file for which to execute the rule.
  /// - parameter collectedInfo:     All collected info for all files.
  /// - parameter compilerArguments: The compiler arguments needed to compile this file.
  ///
  /// - returns: All style violations to the rule's expectations.
  func validate(
    file: SwiftSource,
    collectedInfo: [SwiftSource: FileInfo],
    compilerArguments: [String],
  ) -> [RuleViolation]

  /// Executes the rule on a file after collecting file info for all files and returns any violations to the rule's
  /// expectations.
  ///
  /// - parameter file:          The file for which to execute the rule.
  /// - parameter collectedInfo: All collected info for all files.
  ///
  /// - returns: All style violations to the rule's expectations.
  func validate(file: SwiftSource, collectedInfo: [SwiftSource: FileInfo]) -> [RuleViolation]
}

extension CollectingRule {
  func collectInfo(
    for file: SwiftSource,
    into storage: RuleStorage,
    compilerArguments: [String],
  ) {
    storage.collect(
      info: collectInfo(for: file, compilerArguments: compilerArguments),
      for: file, in: self,
    )
  }

  func validate(file: SwiftSource, using storage: RuleStorage, compilerArguments: [String])
    -> [RuleViolation]
  {
    guard let info = storage.collectedInfo(for: self) else {
      queuedFatalError("Attempt to validate a CollectingRule before collecting info for it")
    }
    return validate(file: file, collectedInfo: info, compilerArguments: compilerArguments)
  }

  func collectInfo(for file: SwiftSource, compilerArguments _: [String]) -> FileInfo {
    collectInfo(for: file)
  }

  func validate(
    file: SwiftSource,
    collectedInfo: [SwiftSource: FileInfo],
    compilerArguments _: [String],
  ) -> [RuleViolation] {
    validate(file: file, collectedInfo: collectedInfo)
  }

  func validate(file _: SwiftSource) -> [RuleViolation] {
    queuedFatalError("Must call `validate(file:collectedInfo:)` for CollectingRule")
  }

  func validate(file _: SwiftSource, compilerArguments _: [String]) -> [RuleViolation] {
    queuedFatalError(
      "Must call `validate(file:collectedInfo:compilerArguments:)` for CollectingRule",
    )
  }
}

extension CollectingRule where Self: AnalyzerRule {
  func collectInfo(for _: SwiftSource) -> FileInfo {
    queuedFatalError(
      "Must call `collect(infoFor:compilerArguments:)` for AnalyzerRule & CollectingRule",
    )
  }

  func validate(file _: SwiftSource) -> [RuleViolation] {
    queuedFatalError(
      "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule",
    )
  }

  func validate(file _: SwiftSource, collectedInfo _: [SwiftSource: FileInfo])
    -> [RuleViolation]
  {
    queuedFatalError(
      "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule",
    )
  }
}
