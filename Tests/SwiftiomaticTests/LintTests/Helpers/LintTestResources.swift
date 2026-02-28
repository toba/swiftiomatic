// Adapted from SwiftLint 0.63.2 TestResources.swift (MIT license)

import Foundation
@testable import Swiftiomatic

enum TestResources {
    static func path(_ calleePath: String = #filePath) -> String {
        URL(fileURLWithPath: calleePath, isDirectory: false)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .path
            .absolutePathStandardized()
    }
}
