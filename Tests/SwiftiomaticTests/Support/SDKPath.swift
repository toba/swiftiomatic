import Foundation
import Subprocess
import SwiftiomaticSyntax
import Synchronization

private let cachedSDKPath = Mutex<String?>(nil)

private let defaultSDKPath =
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

func macOSSDKPath() async -> String {
    if let cached = cachedSDKPath.withLock({ $0 }) {
        return cached
    }
    let resolved: String
    do {
        let result = try await run(
            .name("xcrun"),
            arguments: ["--show-sdk-path", "--sdk", "macosx"],
            output: .string(limit: 4096)
        )
        let trimmed =
            result.standardOutput?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        resolved = trimmed.isEmpty ? defaultSDKPath : trimmed
    } catch {
        resolved = defaultSDKPath
    }
    cachedSDKPath.withLock { $0 = resolved }
    return resolved
}

