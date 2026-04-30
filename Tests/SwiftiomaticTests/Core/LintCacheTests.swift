import Foundation
@testable import SwiftiomaticKit
import Testing

@Suite struct LintCacheTests {
    @Test func hexEncodeMatchesStringFormat() {
        let bytes: [UInt8] = [0x00, 0x0f, 0x10, 0xab, 0xff]
        let expected = bytes.map { String(format: "%02x", $0) }.joined()
        #expect(LintCache.hexEncode(bytes) == expected)
    }

    @Test func hexEncodeEmpty() {
        #expect(LintCache.hexEncode([UInt8]()) == "")
    }

    @Test func contentHashIsLowercaseHex() {
        let hash = LintCache.contentHash(of: "let x = 1\n")
        #expect(hash.count == 64)
        #expect(hash.allSatisfy { "0123456789abcdef".contains($0) })
    }

    @Test func cacheEligibleRejectsNonFileURL() {
        let url = URL(string: "https://example.com/foo.swift")!
        #expect(
            !LintCache.isCacheEligible(
                url: url, lines: [], offsets: [], ignoreUnparsableFiles: false
            )
        )
    }

    @Test func cacheEligibleRejectsLines() {
        let url = URL(fileURLWithPath: "/tmp/x.swift")
        #expect(
            !LintCache.isCacheEligible(
                url: url, lines: [1...3], offsets: [], ignoreUnparsableFiles: false
            )
        )
    }

    @Test func cacheEligibleRejectsIgnoreUnparsable() {
        let url = URL(fileURLWithPath: "/tmp/x.swift")
        #expect(
            !LintCache.isCacheEligible(
                url: url, lines: [], offsets: [], ignoreUnparsableFiles: true
            )
        )
    }

    @Test func cacheEligibleAcceptsRegularFile() {
        let url = URL(fileURLWithPath: "/tmp/x.swift")
        #expect(
            LintCache.isCacheEligible(
                url: url, lines: [], offsets: [], ignoreUnparsableFiles: false
            )
        )
    }
}
