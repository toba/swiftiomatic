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
}
