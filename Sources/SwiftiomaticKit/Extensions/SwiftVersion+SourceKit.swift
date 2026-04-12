import Foundation
import SwiftiomaticSyntax

/// Detects the Swift compiler version via SourceKit at startup.
///
/// This code lives in SwiftiomaticKit (not SwiftiomaticSyntax) because it
/// depends on SourceKit types (`UID`, `SourceKitObject`, `Request`, `CurrentRule`).
extension SwiftVersion {
  /// Detect the Swift version via SourceKit and update ``SwiftVersion/current``.
  ///
  /// Call once during app startup, before any rule evaluation begins.
  package static func detectViaSourceKit() {
    // If an environment override is already active, nothing to do.
    if ProcessInfo.processInfo.environment["SWIFTIOMATIC_SWIFT_VERSION"] != nil {
      return
    }
    // Check BEFORE creating UID/SourceKitObject — those trigger dlopen of
    // sourcekitdInProc.framework which spawns background threads that SIGSEGV
    // on process exit (apple/swift#55112).
    guard !isSourceKitDisabled else { return }
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
      SwiftVersion.current = SwiftVersion(rawValue: "\(major).\(minor).\(patch)")
    }
  }
}
