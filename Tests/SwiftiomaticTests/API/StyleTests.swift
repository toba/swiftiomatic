@testable import ConfigurationKit
import Foundation
@testable import SwiftiomaticKit
import Testing

@Suite
struct StyleTests {
    @Test func defaultStyleIsCompact() {
        let config = Configuration()
        #expect(config[StyleSetting.self] == .compact)
    }

    @Test func styleEnumExposesBothCases() {
        #expect(Style.allCases.contains(.compact))
        #expect(Style.allCases.contains(.roomy))
    }

    @Test func compactPassesValidation() throws {
        let config = Configuration()
        try config.validateStyleSupported()
    }

    @Test func roomyFailsValidationWithStyleNotImplemented() {
        var config = Configuration()
        config[StyleSetting.self] = .roomy
        #expect(throws: SwiftiomaticError.styleNotImplemented("roomy")) {
            try config.validateStyleSupported()
        }
    }

    @Test func styleDecodesFromJSON() throws {
        let json = #"{ "style": "roomy" }"#.data(using: .utf8)!
        let config = try Configuration(data: json)
        #expect(config[StyleSetting.self] == .roomy)
    }

    /// Smoke test for the compact-pipeline dispatch site (`q4d-ya9`). With the default
    /// style (`.compact`), `RewriteCoordinator.format(...)` produces non-empty output —
    /// proving the new switch routes to `runCompactPipeline` without breaking existing
    /// behavior.
    @Test func compactPipelineDispatchProducesOutput() throws {
        let coordinator = RewriteCoordinator(
            configuration: Configuration(),
            findingConsumer: { _ in }
        )
        var out = ""
        try coordinator.format(
            source: "let x = 1\n",
            assumingFileURL: nil,
            selection: .infinite,
            to: &out
        )
        #expect(!out.isEmpty)
    }
}
