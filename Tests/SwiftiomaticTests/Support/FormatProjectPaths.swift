import Foundation
@testable import Swiftiomatic

let formatProjectDirectory = URL(filePath: #filePath)
    .deletingLastPathComponent() // Support/
    .deletingLastPathComponent() // SwiftiomaticTests/
    .deletingLastPathComponent() // Tests/
    .deletingLastPathComponent() // swiftiomatic/
