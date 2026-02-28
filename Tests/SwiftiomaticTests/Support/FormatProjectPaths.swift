import Foundation
@testable import Swiftiomatic

let formatProjectDirectory = URL(filePath: #filePath)
    .deletingLastPathComponent() // Helpers/
    .deletingLastPathComponent() // FormatTests/
    .deletingLastPathComponent() // SwiftiomaticTests/
    .deletingLastPathComponent() // Tests/
