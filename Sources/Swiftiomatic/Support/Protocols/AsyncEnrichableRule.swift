/// A rule that can produce additional violations via async SourceKit enrichment.
///
/// After the synchronous `validate()` pass, the Analyzer calls `enrichAsync()`
/// for conforming rules when a `TypeResolver` is available. This allows rules
/// to resolve types, check USRs, or query expression types to upgrade
/// confidence or add findings that require semantic information.
///
/// The protocol is additive — it does not change the synchronous `Rule.validate()` contract.
protocol AsyncEnrichableRule: Rule {
    /// Produce additional violations by resolving types via SourceKit.
    ///
    /// Called after `validate()` when a `TypeResolver` is available.
    /// Returns only the *new* violations discovered through async enrichment;
    /// the Analyzer merges them with the synchronous results.
    ///
    /// - Parameters:
    ///   - file: The file being analyzed.
    ///   - typeResolver: A connected SourceKit type resolver.
    /// - Returns: Additional violations found through type resolution.
    func enrichAsync(
        file: SwiftLintFile,
        typeResolver: any TypeResolver,
    ) async -> [StyleViolation]
}
