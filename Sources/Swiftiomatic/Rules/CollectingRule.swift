/// Marker protocol used to check whether a rule is collectable
public protocol CollectingRuleMarker: Rule {}

/// A rule that requires knowledge of all other files being linted
///
/// Conforming rules implement a two-pass workflow: pass 1 calls ``collectInfo(for:)``
/// on every file, then pass 2 calls ``validate(file:collectedInfo:)`` with the
/// aggregated results.
protocol CollectingRule: CollectingRuleMarker {
  /// The kind of information to collect for each file being linted for this rule
  associatedtype FileInfo

  /// Collect file-level information for the specified file
  ///
  /// - Parameters:
  ///   - file: The file for which to collect info.
  ///   - compilerArguments: The compiler arguments needed to compile this file.
  /// - Returns: The collected file information.
  func collectInfo(for file: SwiftSource, compilerArguments: [String]) -> FileInfo

  /// Collect file-level information without compiler arguments
  ///
  /// - Parameters:
  ///   - file: The file for which to collect info.
  /// - Returns: The collected file information.
  func collectInfo(for file: SwiftSource) -> FileInfo

  /// Validate a file using the aggregated info from all files
  ///
  /// - Parameters:
  ///   - file: The file for which to execute the rule.
  ///   - collectedInfo: All collected info for all files.
  ///   - compilerArguments: The compiler arguments needed to compile this file.
  /// - Returns: All style violations to the rule's expectations.
  func validate(
    file: SwiftSource,
    collectedInfo: [SwiftSource: FileInfo],
    compilerArguments: [String],
  ) -> [RuleViolation]

  /// Validate a file using the aggregated info from all files, without compiler arguments
  ///
  /// - Parameters:
  ///   - file: The file for which to execute the rule.
  ///   - collectedInfo: All collected info for all files.
  /// - Returns: All style violations to the rule's expectations.
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
      Console.fatalError("Attempt to validate a CollectingRule before collecting info for it")
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
    Console.fatalError("Must call `validate(file:collectedInfo:)` for CollectingRule")
  }

  func validate(file _: SwiftSource, compilerArguments _: [String]) -> [RuleViolation] {
    Console.fatalError(
      "Must call `validate(file:collectedInfo:compilerArguments:)` for CollectingRule",
    )
  }
}

extension CollectingRule where Self: AnalyzerRule {
  func collectInfo(for _: SwiftSource) -> FileInfo {
    Console.fatalError(
      "Must call `collect(infoFor:compilerArguments:)` for AnalyzerRule & CollectingRule",
    )
  }

  func validate(file _: SwiftSource) -> [RuleViolation] {
    Console.fatalError(
      "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule",
    )
  }

  func validate(file _: SwiftSource, collectedInfo _: [SwiftSource: FileInfo])
    -> [RuleViolation]
  {
    Console.fatalError(
      "Must call `validate(file:collectedInfo:compilerArguments:)` for AnalyzerRule & CollectingRule",
    )
  }
}
