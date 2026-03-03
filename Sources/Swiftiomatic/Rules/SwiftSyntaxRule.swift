import Foundation
import SwiftSyntax

/// A Swiftiomatic ``Rule`` backed by SwiftSyntax that does not use SourceKit requests
protocol SwiftSyntaxRule: Rule {
    /// Produce a ``ViolationCollectingVisitor`` for the given file
    ///
    /// - Parameters:
    ///   - file: The file for which to produce the visitor.
    /// - Returns: A ``ViolationCollectingVisitor`` for the given file.
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType>

    /// Produce a ``RuleViolation`` for the given file and syntax violation
    ///
    /// - Parameters:
    ///   - file: The file for which to produce the violation.
    ///   - violation: A violation in the file.
    /// - Returns: A violation for the given file and absolute position.
    func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation

    /// Pre-process the syntax tree before checking for violations
    ///
    /// Override this to fold operators or skip validation in certain files.
    /// By default returns the file's `syntaxTree`.
    ///
    /// - Parameters:
    ///   - file: The file to run pre-processing on.
    /// - Returns: The tree that will be used to check for violations, or `nil` to produce no violations.
    func preprocess(file: SwiftSource) -> SourceFileSyntax?

    /// Produce a ``ViolationCollectingRewriter`` for the given file
    ///
    /// Only needed for correctable rules. Returns `nil` by default, which falls back
    /// to the visitor's collected `violationCorrections`.
    ///
    /// - Parameters:
    ///   - file: The file for which to produce the rewriter.
    /// - Returns: A ``ViolationCollectingRewriter`` for the given file, or `nil` to fall back
    ///   to the visitor's collected `violationCorrections`.
    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>?
}

extension SwiftSyntaxRule where OptionsType: SeverityBasedRuleOptions {
    func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation {
        RuleViolation(
            ruleType: Self.self,
            severity: violation.severity ?? options.severity,
            location: Location(file: file, position: violation.position),
            message: violation.reason,
            confidence: violation.confidence,
            suggestion: violation.suggestion,
        )
    }
}

extension SwiftSyntaxRule {
    @inlinable
    func validate(file: SwiftSource) -> [RuleViolation] {
        guard let syntaxTree = preprocess(file: file) else {
            return []
        }

        let violations = makeVisitor(file: file)
            .walk(tree: syntaxTree, handler: \.violations)
        assert(
            violations
                .allSatisfy { $0.correction == nil || Self.isCorrectable },
            "\(Self.self) produced corrections without being correctable.",
        )
        return
            violations
                .sorted()
                .map { makeViolation(file: file, violation: $0) }
    }

    func makeViolation(file: SwiftSource, violation: SyntaxViolation) -> RuleViolation {
        guard let severity = violation.severity else {
            // This error will only be thrown in tests. It cannot come up at runtime.
            Console.fatalError(
                """
                A severity must be provided. Either define it in the violation or make the rule configuration \
                conform to `SeverityBasedRuleOptions` to take the default.
                """,
            )
        }
        return RuleViolation(
            ruleType: Self.self,
            severity: severity,
            location: Location(file: file, position: violation.position),
            message: violation.reason,
            confidence: violation.confidence,
            suggestion: violation.suggestion,
        )
    }

    func preprocess(file: SwiftSource) -> SourceFileSyntax? {
        file.syntaxTree
    }

    func makeRewriter(file _: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        nil
    }

    /// Create a type-erased visitor for use in the lint pipeline
    func makePipelineVisitor(file: SwiftSource) -> SyntaxVisitor &
        ViolationCollectingVisitorProtocol
    {
        makeVisitor(file: file)
    }

    func correct(file: SwiftSource) -> Int {
        guard Self.isCorrectable else { return 0 }
        guard let syntaxTree = preprocess(file: file) else {
            return 0
        }
        if let rewriter = makeRewriter(file: file) {
            let newTree = rewriter.visit(syntaxTree)
            file.write(newTree.description)
            return rewriter.numberOfCorrections
        }

        // There is no rewriter. Falling back to the correction ranges collected by the visitor (if any).
        let violations = makeVisitor(file: file)
            .walk(tree: syntaxTree, handler: \.violations)
        guard violations.isNotEmpty else {
            return 0
        }

        let locationConverter = file.locationConverter
        let disabledRegions = file.regions()
            .filter { $0.areRulesDisabled(ruleIDs: Self.allIdentifiers) }
            .compactMap { $0.toSourceRange(locationConverter: locationConverter) }

        typealias CorrectionRange = (range: Range<String.Index>, correction: String)
        let correctionRanges =
            violations
                .filter {
                    !$0.position.isContainedIn(
                        regions: disabledRegions,
                        locationConverter: locationConverter,
                    )
                }
                .compactMap(\.correction)
                .compactMap { correction in
                    file.stringView.stringRange(start: correction.start, end: correction.end)
                        .map { range in
                            CorrectionRange(range: range, correction: correction.replacement)
                        }
                }
                .sorted { (lhs: CorrectionRange, rhs: CorrectionRange) -> Bool in
                    lhs.range.lowerBound > rhs.range.lowerBound
                }
        guard correctionRanges.isNotEmpty else {
            return 0
        }

        var contents = file.contents
        for range in correctionRanges {
            contents.replaceSubrange(range.range, with: range.correction)
        }
        file.write(contents)
        return correctionRanges.count
    }
}

/// A SwiftSyntax `SyntaxRewriter` that produces absolute positions where corrections were applied
class ViolationCollectingRewriter<Configuration: RuleOptions>: SyntaxRewriter {
    /// The rule's configuration
    let configuration: Configuration
    /// The file from which the traversed syntax tree stems
    let file: SwiftSource

    /// A converter of positions in the traversed source file
    let locationConverter: SourceLocationConverter
    /// The regions in the traversed file that are disabled by a command
    let disabledRegions: [SourceRange]

    /// The number of corrections made by the rewriter
    var numberOfCorrections = 0

    /// Create a ``ViolationCollectingRewriter``
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: File from which the syntax tree stems.
    init(configuration: Configuration, file: SwiftSource) {
        self.configuration = configuration
        self.file = file
        locationConverter = file.locationConverter
        disabledRegions = file.regions()
            .filter { $0.areRulesDisabled(ruleIDs: Configuration.Parent.allIdentifiers) }
            .compactMap { $0.toSourceRange(locationConverter: file.locationConverter) }
    }

    /// Determine whether the rule is disabled at the start position of the given syntax node
    ///
    /// - Parameters:
    ///   - node: The syntax node to check.
    /// - Returns: `true` if the rule is disabled for the node.
    func isDisabled(atStartPositionOf node: some SyntaxProtocol) -> Bool {
        node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
    }

    override func visitAny(_ node: Syntax) -> Syntax? {
        isDisabled(atStartPositionOf: node) ? node : nil
    }
}
