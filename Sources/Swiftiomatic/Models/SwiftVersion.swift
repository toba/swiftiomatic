import Foundation

/// A value describing the version of the Swift compiler.
package struct SwiftVersion: RawRepresentable, Codable, VersionComparable, Sendable {
    package typealias RawValue = String

    package let rawValue: String

    package init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension SwiftVersion {
    /// Swift 6
    static let v6 = SwiftVersion(rawValue: "6.0.0")
    /// Swift 6.1
    static let v6_1 = SwiftVersion(rawValue: "6.1.0")
    /// Swift 6.1.1
    static let v6_1_1 = SwiftVersion(rawValue: "6.1.1")
    /// Swift 6.1.2
    static let v6_1_2 = SwiftVersion(rawValue: "6.1.2")
    /// Swift 6.2
    static let v6_2 = SwiftVersion(rawValue: "6.2.0")
    /// Swift 6.2.1
    static let v6_2_1 = SwiftVersion(rawValue: "6.2.1")
    /// Swift 6.2.2
    static let v6_2_2 = SwiftVersion(rawValue: "6.2.2")
    /// Swift 6.2.3
    static let v6_2_3 = SwiftVersion(rawValue: "6.2.3")
    /// Swift 6.3
    static let v6_3 = SwiftVersion(rawValue: "6.3.0")

    /// The current detected Swift compiler version, based on the currently accessible SourceKit version.
    ///
    /// - note: Override by setting the `SWIFTIOMATIC_SWIFT_VERSION` environment variable.
    static let current: SwiftVersion = {
        // Allow forcing the Swift version, useful in cases where SourceKit isn't available.
        if let envVersion = ProcessInfo.processInfo.environment["SWIFTIOMATIC_SWIFT_VERSION"] {
            return SwiftVersion(rawValue: envVersion)
        }
        // Check BEFORE creating UID/SourceKitObject — those trigger dlopen of
        // sourcekitdInProc.framework which spawns background threads that SIGSEGV
        // on process exit (apple/swift#55112).
        guard !isSourceKitDisabled else { return .compileTime }
        // This request was added in Swift 5.1
        let params: SourceKitObject = ["key.request": UID("source.request.compiler_version")]
        // Allow this specific SourceKit request outside of rule execution context
        let result = CurrentRule.$allowSourceKitRequestWithoutRule.withValue(true) {
            try? Request.customRequest(request: params).sendIfNotDisabled()
        }
        if let result,
           let major = result["key.version_major"]?.int64Value.map(Int.init),
           let minor = result["key.version_minor"]?.int64Value.map(Int.init),
           let patch = result["key.version_patch"]?.int64Value.map(Int.init)
        {
            return SwiftVersion(rawValue: "\(major).\(minor).\(patch)")
        }
        return .compileTime
    }()

    /// Compile-time Swift version detected via `#if compiler()` directives.
    /// Used as a fallback when SourceKit is unavailable.
    private static let compileTime: SwiftVersion = {
        #if compiler(>=6.3.0)
        return SwiftVersion(rawValue: "6.3.0")
        #elseif compiler(>=6.2.4)
        return SwiftVersion(rawValue: "6.2.4")
        #elseif compiler(>=6.2.3)
        return SwiftVersion(rawValue: "6.2.3")
        #elseif compiler(>=6.2.2)
        return SwiftVersion(rawValue: "6.2.2")
        #elseif compiler(>=6.2.1)
        return SwiftVersion(rawValue: "6.2.1")
        #elseif compiler(>=6.2.0)
        return SwiftVersion(rawValue: "6.2.0")
        #elseif compiler(>=6.1.2)
        return SwiftVersion(rawValue: "6.1.2")
        #elseif compiler(>=6.1.1)
        return SwiftVersion(rawValue: "6.1.1")
        #elseif compiler(>=6.1.0)
        return SwiftVersion(rawValue: "6.1.0")
        #elseif compiler(>=6.0.0)
        return SwiftVersion(rawValue: "6.0.0")
        #else
        return .v6
        #endif
    }()
}
