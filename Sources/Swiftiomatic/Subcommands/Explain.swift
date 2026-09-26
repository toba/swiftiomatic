import ArgumentParser
import SwiftiomaticKit

extension SwiftiomaticCommand {
    /// Prints the documentation of a rule, or a one-line summary of every rule.
    struct Explain: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Explain a rule",
            discussion: """
                With a rule, prints its guidance level, when it applies, and its full \
                documentation. Without a rule, prints one line per rule with its key, guidance \
                level and applicability.
                """
        )

        @Argument(help: "A rule key, a qualified key such as 'redundancies.dropRedundantBreak', or a rule type name.")
        var rule: String?

        func run() throws {
            guard let rule else {
                print(RuleCatalog.listing())
                return
            }
            guard let info = RuleCatalog.info(for: rule) else {
                throw ValidationError("unknown rule '\(rule)'. Run 'sm explain' to list the rules.")
            }
            print(RuleCatalog.explanation(of: info))
        }
    }
}
