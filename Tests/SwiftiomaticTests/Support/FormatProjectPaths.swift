import Foundation
@testable import Swiftiomatic

let formatProjectDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent() // Helpers/
    .deletingLastPathComponent() // FormatTests/
    .deletingLastPathComponent() // SwiftiomaticTests/
    .deletingLastPathComponent() // Tests/
