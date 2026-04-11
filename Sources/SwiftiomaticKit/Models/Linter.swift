import Foundation
import SwiftSyntax

// sm:disable file_length

private let warnSourceKitFailedOnceImpl: Void = {
  SwiftiomaticError
    .genericWarning("SourceKit-based rules will be skipped because sourcekitd has failed.")
    .print()
}()

private func warnSourceKitFailedOnce() {
  _ = warnSourceKitFailedOnceImpl
}

private struct LintResult {
  let violations: [RuleViolation]
  let ruleTime: (id: String, time: Double)?
  let deprecatedToValidIDPairs: [(String, String)]
}

extension Rule {
  private func redundantDisableCommandViolations(
    regions: [Region],
    redundantDisableCommandRule: RedundantDisableCommandRule?,
    allViolations: [RuleViolation],
  ) -> [RuleViolation] {
    guard regions.isNotEmpty, let redundantDisableCommandRule else {
      return []
    }

    let regions = regions.perIdentifierRegions

    let regionsDisablingRedundantDisableRule = regions.filter { region in
      region.isRuleDisabled(redundantDisableCommandRule)
    }

    var redundantDisableCommandViolations = [RuleViolation]()
    for region in regions {
      if regionsDisablingRedundantDisableRule
        .contains(where: { $0.contains(region.start) })
      {
        continue
      }
      guard let disabledRuleIdentifier = region.disabledRuleIdentifiers.first else {
        continue
      }
      guard !isEnabled(in: region, for: disabledRuleIdentifier.stringRepresentation) else {
        continue
      }
      var disableCommandValid = false
      for violation in allViolations where region.contains(violation.location) {
        if canBeDisabled(violation: violation, by: disabledRuleIdentifier) {
          disableCommandValid = true
          break
        }
      }
      if !disableCommandValid {
        let reason = redundantDisableCommandRule.reason(
          forRuleIdentifier: disabledRuleIdentifier.stringRepresentation,
        )
        redundantDisableCommandViolations.append(
          RuleViolation(
            anyRuleType: type(of: redundantDisableCommandRule),
            severity: redundantDisableCommandRule.options.severity,
            location: region.start,
            reason: reason,
          ),
        )
      }
    }
    return redundantDisableCommandViolations
  }

  fileprivate func shouldRun(onFile file: SwiftSource) -> Bool {
    // We shouldn't lint if the current Swift version is not supported by the rule
    guard SwiftVersion.current >= Self.minSwiftVersion else {
      return false
    }

    // Empty files shouldn't trigger violations if `shouldLintEmptyFiles` is `false`
    if file.isEmpty, !shouldLintEmptyFiles {
      return false
    }

    if requiresSourceKit {
      // Only check `sourcekitdFailed` if the rule requires SourceKit. This avoids triggering SourceKit
      // initialization for effectively SourceKit-free rules.
      if file.sourcekitdFailed {
        warnSourceKitFailedOnce()
        return false
      }
    }
    return true
  }

  // As we need the configuration to get custom identifiers.
  // sm:disable:next function_parameter_count
  fileprivate func lint(
    file: SwiftSource,
    regions: [Region],
    benchmark: Bool,
    storage: RuleStorage,
    redundantDisableCommandRule: RedundantDisableCommandRule?,
    compilerArguments: [String],
  ) -> LintResult {
    let ruleID = Self.identifier

    // Wrap entire lint process including shouldRun check in rule context
    return CurrentRule.$identifier.withValue(ruleID) {
      guard shouldRun(onFile: file) else {
        return LintResult(violations: [], ruleTime: nil, deprecatedToValidIDPairs: [])
      }

      return performLint(
        file: file,
        regions: regions,
        benchmark: benchmark,
        storage: storage,
        redundantDisableCommandRule: redundantDisableCommandRule,
        compilerArguments: compilerArguments,
      )
    }
  }

  // sm:disable:next function_parameter_count
  private func performLint(
    file: SwiftSource,
    regions: [Region],
    benchmark: Bool,
    storage: RuleStorage,
    redundantDisableCommandRule: RedundantDisableCommandRule?,
    compilerArguments: [String],
  ) -> LintResult {
    let violations = validate(file: file, using: storage, compilerArguments: compilerArguments)
    return filterViolations(
      violations,
      file: file,
      regions: regions,
      benchmark: benchmark,
      ruleTime: nil,
      redundantDisableCommandRule: redundantDisableCommandRule,
    )
  }

  /// Filter pre-computed violations through region/disable-command logic
  // sm:disable:next function_parameter_count
  fileprivate func filterViolations(
    _ violations: [RuleViolation],
    file: SwiftSource,
    regions: [Region],
    benchmark _: Bool,
    ruleTime: (String, Double)?,
    redundantDisableCommandRule: RedundantDisableCommandRule?,
  ) -> LintResult {
    let ruleID = Self.identifier

    let (disabledViolationsAndRegions, enabledViolationsAndRegions) =
      violations
      .map { violation in
        (violation, regions.first { $0.contains(violation.location) })
      }.partitioned { violation, region in
        if let region {
          return isEnabled(in: region, for: violation.ruleIdentifier)
        }
        return true
      }

    let ruleIDs =
      Self.allIdentifiers
      + (redundantDisableCommandRule.map { type(of: $0) }?.allIdentifiers ?? []) + [
        RuleIdentifier.all.stringRepresentation
      ]
    let ruleIdentifiers = Set(ruleIDs.map { RuleIdentifier($0) })

    let redundantDisableCommandViolations = redundantDisableCommandViolations(
      regions: regions.count > 1
        ? file.regions(restrictingRuleIdentifiers: ruleIdentifiers) : regions,
      redundantDisableCommandRule: redundantDisableCommandRule,
      allViolations: violations,
    )

    let enabledViolations: [RuleViolation]
    if file.contents
      .hasPrefix("#!")
    {  // if a violation happens on the same line as a shebang, ignore it
      enabledViolations = enabledViolationsAndRegions.compactMap { violation, _ in
        if violation.location.line == 1 { return nil }
        return violation
      }
    } else {
      enabledViolations = enabledViolationsAndRegions.map(\.0)
    }
    let deprecatedToValidIDPairs = disabledViolationsAndRegions.flatMap {
      _, region -> [(String, String)] in
      let identifiers = region?.deprecatedAliasesDisabling(rule: self) ?? []
      return identifiers.map { ($0, ruleID) }
    }

    return LintResult(
      violations: enabledViolations + redundantDisableCommandViolations,
      ruleTime: ruleTime,
      deprecatedToValidIDPairs: deprecatedToValidIDPairs,
    )
  }
}

extension [Region] {
  /// Normally regions correspond to changes in the set of enabled rules. To detect redundant disable command
  /// rule violations effectively, we need individual regions for each disabled rule identifier.
  fileprivate var perIdentifierRegions: [Region] {
    guard isNotEmpty else {
      return []
    }

    var convertedRegions = [Region]()
    var startMap: [RuleIdentifier: Location] = [:]
    var lastRegionEnd: Location?

    for region in self {
      let ruleIdentifiers = startMap.keys.sorted()
      for ruleIdentifier in ruleIdentifiers
      where !region.disabledRuleIdentifiers.contains(ruleIdentifier) {
        if let lastRegionEnd, let start = startMap[ruleIdentifier] {
          let newRegion = Region(
            start: start, end: lastRegionEnd, disabledRuleIdentifiers: [ruleIdentifier],
          )
          convertedRegions.append(newRegion)
          startMap[ruleIdentifier] = nil
        }
      }
      for ruleIdentifier in region.disabledRuleIdentifiers
      where startMap[ruleIdentifier] == nil {
        startMap[ruleIdentifier] = region.start
      }
      if region.disabledRuleIdentifiers.isEmpty {
        convertedRegions.append(region)
      }
      lastRegionEnd = region.end
    }

    let end = Location(file: first?.start.file, line: .max, column: .max)
    for ruleIdentifier in startMap.keys.sorted() {
      if let start = startMap[ruleIdentifier] {
        let newRegion = Region(
          start: start,
          end: end,
          disabledRuleIdentifiers: [ruleIdentifier],
        )
        convertedRegions.append(newRegion)
        startMap[ruleIdentifier] = nil
      }
    }

    return convertedRegions.sorted {
      if $0.start == $1.start {
        if let lhsDisabledRuleIdentifier = $0.disabledRuleIdentifiers.first,
          let rhsDisabledRuleIdentifier = $1.disabledRuleIdentifiers.first
        {
          return lhsDisabledRuleIdentifier < rhsDisabledRuleIdentifier
        }
      }
      return $0.start < $1.start
    }
  }
}

/// Represents a file that can be linted for style violations and corrections after being collected.
struct Linter: @unchecked Sendable {
  /// The file to lint with this linter.
  let file: SwiftSource
  /// Whether or not this linter will be used to collect information from several files.
  var isCollecting: Bool
  fileprivate let rules: [any Rule]
  fileprivate let cache: LinterCache?
  fileprivate let configuration: Configuration
  fileprivate let compilerArguments: [String]

  /// Creates a `Linter` by specifying its properties directly.
  ///
  /// - Parameters:
  ///   - file: The file to lint with this linter.
  ///   - configuration: The configuration to apply to this linter.
  ///   - cache: The persisted cache to use for this linter.
  ///   - compilerArguments: The compiler arguments to use for this linter if it is to execute analyzer rules.
  init(
    file: SwiftSource,
    configuration: Configuration = Configuration.default,
    cache: LinterCache? = nil,
    compilerArguments: [String] = [],
  ) {
    self.file = file
    self.cache = cache
    self.configuration = configuration
    self.compilerArguments = compilerArguments

    let rules = configuration.rules.filter { rule in
      if compilerArguments.isEmpty {
        return !type(of: rule).runsWithCompilerArguments
      }
      return type(of: rule).runsWithCompilerArguments || rule is RedundantDisableCommandRule
    }
    self.rules = rules
    isCollecting = rules.contains(where: { type(of: $0).isCrossFile })
  }

  /// Returns a linter capable of checking for violations after running each rule's collection step.
  ///
  /// - Parameters:
  ///   - storage: The storage object where collected info should be saved.
  ///
  /// - Returns: A linter capable of checking for violations after running each rule's collection step.
  func collect(into storage: RuleStorage) async -> CollectedLinter {
    await withTaskGroup(of: Void.self) { group in
      for idx in rules.indices {
        group.addTask {
          let rule = rules[idx]
          let ruleID = type(of: rule).identifier
          CurrentRule.$identifier.withValue(ruleID) {
            rule.collectInfo(
              for: file,
              into: storage,
              compilerArguments: compilerArguments,
            )
          }
        }
      }
    }
    return CollectedLinter(from: self)
  }
}

/// Represents a file that can compute style violations and corrections for a list of rules.
///
/// A `CollectedLinter` is only created after a `Linter` has run its collection steps in `Linter.collect(into:)`.
struct CollectedLinter: @unchecked Sendable {
  /// The file to lint with this linter.
  let file: SwiftSource
  private let rules: [any Rule]
  private let cache: LinterCache?
  private let configuration: Configuration
  private let compilerArguments: [String]

  fileprivate init(from linter: Linter) {
    file = linter.file
    rules = linter.rules
    cache = linter.cache
    configuration = linter.configuration
    compilerArguments = linter.compilerArguments
  }

  /// Computes or retrieves style violations.
  ///
  /// - Parameters:
  ///   - storage: The storage object containing all collected info.
  ///
  /// - Returns: All style violations found by this linter.
  func ruleViolations(using storage: RuleStorage) -> [RuleViolation] {
    getRuleViolations(using: storage).0
  }

  /// Computes or retrieves style violations and the time spent executing each rule.
  ///
  /// - Parameters:
  ///   - storage: The storage object containing all collected info.
  ///
  /// - Returns: All style violations found by this linter, and the time spent executing each rule.
  func ruleViolationsAndRuleTimes(using storage: RuleStorage)
    -> ([RuleViolation], [(id: String, time: Double)])
  {
    getRuleViolations(using: storage, benchmark: true)
  }

  private func getRuleViolations(
    using storage: RuleStorage,
    benchmark: Bool = false,
  ) -> ([RuleViolation], [(id: String, time: Double)]) {
    guard !rules.isEmpty else {
      // Nothing to validate if there are no active rules!
      return ([], [])
    }

    if let cached = cachedRuleViolations(benchmark: benchmark) {
      return cached
    }

    let regions = file.regions()
    let redundantDisableCommandRule =
      rules.first(where: {
        $0 is RedundantDisableCommandRule
      }) as? RedundantDisableCommandRule

    // Partition rules into pipeline-eligible and fallback
    var pipelineRules: [(rule: any SwiftSyntaxRule, index: Int)] = []
    var fallbackRules: [any Rule] = []

    for rule in rules {
      let ruleID = type(of: rule).identifier
      if let syntaxRule = rule as? any SwiftSyntaxRule,
        pipelineEligibleRuleIDs.contains(ruleID),
        !type(of: rule).isCrossFile
      {
        pipelineRules.append((syntaxRule, pipelineRules.count))
      } else {
        fallbackRules.append(rule)
      }
    }

    // Run pipeline rules via single tree walk
    let pipelineResults: [LintResult]
    if pipelineRules.isNotEmpty {
      pipelineResults = runPipeline(
        rules: pipelineRules.map(\.rule),
        file: file,
        regions: regions,
        benchmark: benchmark,
        redundantDisableCommandRule: redundantDisableCommandRule,
      )
    } else {
      pipelineResults = []
    }

    // Run fallback rules via existing per-rule parallel walk
    let fallbackResults: [LintResult] = fallbackRules.parallelMap {
      $0.lint(
        file: file, regions: regions, benchmark: benchmark,
        storage: storage,
        redundantDisableCommandRule: redundantDisableCommandRule,
        compilerArguments: compilerArguments,
      )
    }

    let validationResults = pipelineResults + fallbackResults
    let undefinedRedundantCommandViolations = undefinedRedundantCommandViolations(
      regions: regions, configuration: configuration,
      redundantDisableCommandRule: redundantDisableCommandRule,
    )

    let violations =
      validationResults
      .flatMap(\.violations) + undefinedRedundantCommandViolations
    let ruleTimes = validationResults.compactMap(\.ruleTime)
    var deprecatedToValidIdentifier = [String: String]()
    for (key, value) in validationResults.flatMap(\.deprecatedToValidIDPairs) {
      deprecatedToValidIdentifier[key] = value
    }

    if let cache, let path = file.path {
      cache.cache(violations: violations, forFile: path, configuration: configuration)
    }

    for (deprecatedIdentifier, identifier) in deprecatedToValidIdentifier {
      SwiftiomaticError.renamedIdentifier(old: deprecatedIdentifier, new: identifier).print()
    }

    // Free some memory used for this file's caches. They shouldn't be needed after this point.
    file.invalidateCache()

    return (violations, ruleTimes)
  }

  // sm:disable:next function_parameter_count
  private func runPipeline(
    rules: [any SwiftSyntaxRule],
    file: SwiftSource,
    regions: [Region],
    benchmark: Bool,
    redundantDisableCommandRule: RedundantDisableCommandRule?,
  ) -> [LintResult] {
    let syntaxTree = file.syntaxTree

    // Create visitors and check shouldRun for each rule
    var visitors: [(id: String, visitor: SyntaxVisitor & ViolationCollectingVisitorProtocol)] =
      []
    var ruleForIndex: [(rule: any SwiftSyntaxRule, shouldRun: Bool)] = []

    for rule in rules {
      let ruleID = type(of: rule).identifier
      let shouldRun = CurrentRule.$identifier.withValue(ruleID) {
        rule.shouldRun(onFile: file)
      }
      ruleForIndex.append((rule, shouldRun))
      if shouldRun {
        let visitor = rule.makePipelineVisitor(file: file)
        visitors.append((ruleID, visitor))
      }
    }

    guard visitors.isNotEmpty else {
      return rules.map { _ in
        LintResult(
          violations: [],
          ruleTime: nil,
          deprecatedToValidIDPairs: [],
        )
      }
    }

    // Single tree walk
    let pipeline = LintPipeline(visitors: visitors)
    let pipelineStart = benchmark ? ContinuousClock.now : nil
    pipeline.walk(syntaxTree)
    let pipelineDuration = pipelineStart.map { ContinuousClock.now - $0 }

    // Collect violations from each visitor
    let collectedViolations = pipeline.collectViolations()

    // Map pipeline visitor indices back to rule indices and build LintResults
    var visitorIdx = 0
    var results: [LintResult] = []

    for entry in ruleForIndex {
      let rule = entry.rule
      let ruleID = type(of: rule).identifier

      guard entry.shouldRun else {
        results.append(
          LintResult(
            violations: [],
            ruleTime: nil,
            deprecatedToValidIDPairs: [],
          ),
        )
        continue
      }

      let syntaxViolations = collectedViolations[visitorIdx].violations
      visitorIdx += 1

      // Convert SyntaxViolation -> RuleViolation using the rule's makeViolation
      let ruleViolations =
        syntaxViolations
        .sorted()
        .map { rule.makeViolation(file: file, violation: $0) }

      // Compute per-rule time as fraction of total pipeline time
      let ruleTime: (String, Double)?
      if let pipelineDuration {
        let fraction = pipelineDuration.timeInterval / Double(visitors.count)
        ruleTime = (ruleID, fraction)
      } else {
        ruleTime = nil
      }

      // Run region filtering via existing logic
      let lintResult = CurrentRule.$identifier.withValue(ruleID) {
        rule.filterViolations(
          ruleViolations,
          file: file,
          regions: regions,
          benchmark: benchmark,
          ruleTime: ruleTime,
          redundantDisableCommandRule: redundantDisableCommandRule,
        )
      }
      results.append(lintResult)
    }

    return results
  }

  private func cachedRuleViolations(benchmark: Bool = false) -> (
    [RuleViolation], [(id: String, time: Double)],
  )? {
    let start = ContinuousClock.now
    guard let cache, let file = file.path,
      let cachedViolations = cache.violations(forFile: file, configuration: configuration)
    else {
      return nil
    }

    var ruleTimes = [(id: String, time: Double)]()
    if benchmark {
      // let's assume that all rules should have the same duration and split the duration among them
      let totalTime = (ContinuousClock.now - start).timeInterval
      let fractionedTime = totalTime / Double(rules.count)
      ruleTimes = rules.map { rule in
        let id = type(of: rule).identifier
        return (id, fractionedTime)
      }
    }

    return (cachedViolations, ruleTimes)
  }

  /// Applies corrections for all rules to this file, returning performed corrections.
  ///
  /// - Parameters:
  ///   - storage: The storage object containing all collected info.
  ///
  /// - Returns: All corrections that were applied.
  func correct(using storage: RuleStorage) -> [String: Int] {
    if let violations = cachedRuleViolations()?.0, violations.isEmpty {
      return [:]
    }

    if file.parserDiagnostics.isNotEmpty {
      Console.printError(
        "warning: Skipping correcting file because it produced Swift parser errors: \(file.path ?? "<nopath>")",
      )
      Console.printError(toJSON(["diagnostics": file.parserDiagnostics]))
      return [:]
    }

    var corrections = [String: Int]()
    for rule in rules where type(of: rule).isCorrectable {
      // Set rule context before checking shouldRun to allow file property access
      let ruleCorrections = CurrentRule.$identifier.withValue(type(of: rule).identifier) {
        () -> Int? in
        guard rule.shouldRun(onFile: file) else {
          return nil
        }
        return rule.correct(
          file: file,
          using: storage,
          compilerArguments: compilerArguments,
        )
      }
      if let corrected = ruleCorrections, corrected != 0 {
        corrections[type(of: rule).identifier] = corrected
        if !file.isVirtual {
          file.invalidateCache()
        }
      }
    }
    return corrections
  }

  private func undefinedRedundantCommandViolations(
    regions: [Region],
    configuration _: Configuration,
    redundantDisableCommandRule: RedundantDisableCommandRule?,
  ) -> [RuleViolation] {
    guard regions.isNotEmpty, let redundantDisableCommandRule else {
      return []
    }

    let allRuleIdentifiers = RuleRegistry.shared.list.allValidIdentifiers().map {
      RuleIdentifier($0)
    }
    let allValidIdentifiers = Set(allRuleIdentifiers + [.all])
    let redundantRuleIdentifier = RuleIdentifier(RedundantDisableCommandRule.identifier)

    return regions.flatMap { region in
      region.disabledRuleIdentifiers.filter {
        !allValidIdentifiers.contains($0) && !region.disabledRuleIdentifiers.contains(.all)
          && !region.disabledRuleIdentifiers.contains(redundantRuleIdentifier)
      }.map { id in
        RuleViolation(
          ruleType: type(of: redundantDisableCommandRule),
          severity: redundantDisableCommandRule.options.severity,
          location: region.start,
          reason:
            redundantDisableCommandRule
            .reason(forNonExistentRule: id.stringRepresentation),
        )
      }
    }
  }
}

extension SwiftSource {
  fileprivate var isEmpty: Bool {
    contents.isEmpty || contents == "\n"
  }
}
