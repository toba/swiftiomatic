import Foundation
import Testing
@testable import SwiftiomaticKit

@Suite("RuleCatalog")
struct RuleCatalogTests {
    @Test func everyRuleHasOneSentenceApplicability() {
        #expect(RuleCatalog.all.count == ConfigurationRegistry.allRuleTypes.count)

        for info in RuleCatalog.all {
            #expect(!info.applicability.isEmpty, "\(info.key) has no applicability")
            #expect(!info.applicability.contains("\n"), "\(info.key) applicability spans lines")
            #expect(!info.documentation.isEmpty, "\(info.key) has no documentation")
        }
    }

    @Test func guidanceComesFromGroupOrOverride() throws {
        #expect(try #require(RuleCatalog.info(for: "dropBacktickedSelf")).guidance == .should)
        #expect(try #require(RuleCatalog.info(for: "cyclomaticComplexity")).guidance == .consider)
        #expect(try #require(RuleCatalog.info(for: "noNestedWithLock")).guidance == .must)
    }

    @Test func lookupAcceptsKeyQualifiedKeyAndTypeName() throws {
        let byKey = try #require(RuleCatalog.info(for: "dropBacktickedSelf"))
        #expect(byKey.qualifiedKey == "redundancies.dropBacktickedSelf")
        #expect(RuleCatalog.info(for: "redundancies.dropBacktickedSelf")?.key == byKey.key)
        #expect(RuleCatalog.info(for: "DropBacktickedSelf")?.key == byKey.key)
        #expect(RuleCatalog.info(for: "noSuchRule") == nil)
    }

    @Test func applicabilityIsFirstSentenceOfDocumentation() throws {
        let info = try #require(RuleCatalog.info(for: "dropBacktickedSelf"))
        #expect(info.applicability == "Remove backticks around `self` in optional unwrap expressions.")
    }

    @Test func firstSentenceIgnoresPeriodsInsideCode() {
        #expect(
            RuleCatalog.firstSentence(of: "Lint `a. B` calls. Next sentence.")
                == "Lint `a. B` calls."
        )
        #expect(RuleCatalog.firstSentence(of: "No period at all") == "No period at all")
        #expect(RuleCatalog.firstSentence(of: "One line\nwraps here. Two.") == "One line wraps here.")
    }

    @Test func explanationPrintsGuidanceApplicabilityAndFullDocumentation() throws {
        let text = RuleCatalog.explanation(of: try #require(RuleCatalog.info(for: "dropBacktickedSelf")))
        #expect(text.hasPrefix("dropBacktickedSelf (redundancies.dropBacktickedSelf)\n"))
        #expect(text.contains("Guidance: SHOULD"))
        #expect(text.contains("Applies when: Remove backticks around `self`"))
        #expect(text.contains("Rewrite: The backticks are removed."))
    }

    @Test func listingHasOneLinePerRule() {
        let lines = RuleCatalog.listing().split(separator: "\n")
        #expect(lines.count == RuleCatalog.all.count)
        #expect(lines.contains { $0.hasPrefix("dropBacktickedSelf") && $0.contains("SHOULD") })
    }

    @Test func findingExposesRuleIDAndGuidance() {
        let finding = Finding(
            category: SyntaxFindingCategory(ruleType: NoNestedWithLock.self),
            message: "m"
        )
        #expect(finding.ruleID == "noNestedWithLock")
        #expect(finding.guidance == .must)

        let layout = Finding(category: WhitespaceFindingCategory.lineLength, message: "m")
        #expect(layout.ruleID == nil)
        #expect(layout.guidance == nil)
    }

    @Test func noteRoleDefaultsToRelated() {
        #expect(Finding.Note(message: "m").role == .related)
        #expect(Finding.Note(message: "m", role: .owner).role == .owner)
    }

    @Test func changeStatusFollowsChangedLines() {
        #expect(ChangeStatus(line: 5, changedLines: [3...6]) == .introduced)
        #expect(ChangeStatus(line: 7, changedLines: [3...6, 9...9]) == .existing)
        #expect(ChangeStatus(line: 9, changedLines: [3...6, 9...9]) == .introduced)
    }

    @Test func cachedNoteWithoutRoleStillDecodes() throws {
        let note = try JSONDecoder().decode(
            LintCache.Note.self,
            from: Data(#"{"message":"m"}"#.utf8)
        )
        #expect(note.role == nil)

        let roundTrip = try JSONDecoder().decode(
            LintCache.Note.self,
            from: JSONEncoder().encode(LintCache.Note(message: "m", location: nil, role: .input))
        )
        #expect(roundTrip.role == .input)
    }
}
