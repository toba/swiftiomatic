import Foundation
@testable import Swiftiomatic

enum TestResources {
    /// Maps parent directory names to their resource subdirectory names.
    private static let resourceDirNames: [String: String] = [
        "BuiltInRules": "BuiltInRulesResources",
        "LintTests": "Fixtures",
    ]

    static func path(_ calleePath: String = #filePath) -> String {
        let parentDir = URL(filePath: calleePath, directoryHint: .notDirectory)
            .deletingLastPathComponent()
        let dirName = parentDir.lastPathComponent
        let resourceDir = resourceDirNames[dirName] ?? "Resources"
        return
            parentDir
                .appendingPathComponent(resourceDir)
                .path
                .absolutePathStandardized()
    }
}
