import Foundation
import Testing

@testable import SwiftiomaticKit

/// Compares the new two-stage `compact` pipeline (`CompactStageOneRewriter` +
/// 13 ordered structural passes, behind `DebugOptions.useCompactPipeline`)
/// against the legacy `RewritePipeline` on the golden corpus.
///
/// Divergences are recorded as Issues, not failures: the cutover from legacy
/// to two-stage is gated by `fkt-mgf`, which signs off on parity (and
/// documents any intentional differences in `2kl-d04` §7) before this test
/// becomes a hard assert and `dil-cew` deletes the legacy path.
@Suite
struct CompactPipelineParityTests {
    @Test(arguments: GoldenCorpus.fixtures)
    func twoStageMatchesLegacy(_ fixture: GoldenCorpus.Fixture) throws {
        let source = try String(contentsOf: fixture.input, encoding: .utf8)

        let legacy = try formatted(source: source, fixture: fixture, useTwoStage: false)
        let twoStage = try formatted(source: source, fixture: fixture, useTwoStage: true)

        if legacy != twoStage {
            Issue.record(
                Comment(
                    rawValue: GoldenCorpus.diff(
                        expected: legacy,
                        actual: twoStage,
                        name: "\(fixture.name) (legacy → two-stage)"
                    )))
        }
    }

    private func formatted(
        source: String,
        fixture: GoldenCorpus.Fixture,
        useTwoStage: Bool
    ) throws -> String {
        var out = ""
        let coordinator = RewriteCoordinator(configuration: Configuration())
        if useTwoStage {
            coordinator.debugOptions.insert(.useCompactPipeline)
        }
        try coordinator.format(
            source: source,
            assumingFileURL: fixture.input,
            selection: .infinite,
            to: &out
        )
        return out
    }
}
