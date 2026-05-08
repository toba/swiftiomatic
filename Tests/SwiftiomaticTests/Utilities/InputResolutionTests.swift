import Foundation
import SwiftiomaticKit
import Testing

@Suite struct InputResolutionTests {
    @Test func dashReadsStdin() {
        #expect(resolveInputs(rawPaths: ["-"], stdinIsTTY: true) == .stdin)
        #expect(resolveInputs(rawPaths: ["-"], stdinIsTTY: false) == .stdin)
    }

    @Test func emptyOnTTYRecursesCwd() {
        #expect(
            resolveInputs(rawPaths: [], stdinIsTTY: true)
                == .urls([URL(fileURLWithPath: ".")])
        )
    }

    @Test func emptyWithPipedStdinReadsStdin() {
        #expect(resolveInputs(rawPaths: [], stdinIsTTY: false) == .stdin)
    }

    @Test func explicitPathsResolveToURLs() {
        let resolved = resolveInputs(
            rawPaths: ["Sources", "Tests/foo.swift"],
            stdinIsTTY: true
        )
        #expect(
            resolved
                == .urls([
                    URL(fileURLWithPath: "Sources"),
                    URL(fileURLWithPath: "Tests/foo.swift"),
                ])
        )
    }
}
