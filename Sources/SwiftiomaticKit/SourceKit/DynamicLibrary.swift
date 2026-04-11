import Foundation

// MARK: - Shared Types & Functions

/// A dynamically loaded shared library handle
///
/// Wraps `dlopen` / `dlsym` to load C function pointers from the
/// SourceKit in-process framework at runtime.
struct DynamicLinkLibrary: @unchecked Sendable {
  typealias Handle = UnsafeMutableRawPointer

  fileprivate let handle: Handle

  /// Look up and return a typed function pointer for the given symbol
  ///
  /// Fatally errors if the symbol cannot be resolved.
  ///
  /// - Parameters:
  ///   - symbol: The C symbol name to resolve.
  func load<T>(symbol: String) -> T {
    if let sym = dlsym(handle, symbol) {
      return unsafeBitCast(sym, to: T.self)
    }
    let errorString = String(validatingCString: dlerror())
    fatalError("Finding symbol \(symbol) failed: \(errorString ?? "unknown error")")
  }
}

/// Searches well-known toolchain paths to locate and `dlopen` a dynamic library
struct Loader: Sendable {
  /// Ordered directories to search for the library
  let searchPaths: [String]

  /// Open the dynamic library at the given relative path
  ///
  /// Tries each search path in order, then falls back to the bare path.
  /// Fatally errors if the library cannot be loaded from any location.
  ///
  /// - Parameters:
  ///   - path: The relative path to the dynamic library (e.g. `sourcekitdInProc.framework/...`).
  func load(path: String) -> DynamicLinkLibrary {
    let fullPaths: [String] = searchPaths.map { $0.appending(pathComponent: path) }
      .filter(\.isFile)

    for fullPath in fullPaths + [path] {
      if let handle = dlopen(fullPath, RTLD_LAZY) {
        return DynamicLinkLibrary(handle: handle)
      }
    }

    fatalError("Loading \(path) failed")
  }
}

private func env(_ name: String) -> String? {
  ProcessInfo.processInfo.environment[name]
}

extension String {
  fileprivate func appending(pathComponent: String) -> String {
    URL(fileURLWithPath: self).appendingPathComponent(pathComponent).path
  }

  fileprivate func deleting(lastPathComponents numberOfPathComponents: Int) -> String {
    (0..<numberOfPathComponents)
      .reduce(URL(fileURLWithPath: self)) { url, _ in url.deletingLastPathComponent() }
      .path
  }
}

// MARK: - Darwin

/// Pre-configured ``Loader`` that searches Xcode and command-line toolchain paths for SourceKit
let toolchainLoader = Loader(
  searchPaths: [
    xcodeDefaultToolchainOverride,
    toolchainDir,
    xcrunFindPath,
    applicationsDir?.xcodeDeveloperDir.toolchainDir,
    applicationsDir?.xcodeBetaDeveloperDir.toolchainDir,
    userApplicationsDir?.xcodeDeveloperDir.toolchainDir,
    userApplicationsDir?.xcodeBetaDeveloperDir.toolchainDir,
  ].compactMap { path in
    if let fullPath = path?.usrLibDir, FileManager.default.fileExists(atPath: fullPath) {
      return fullPath
    }
    return nil
  },
)

private let xcodeDefaultToolchainOverride = env("XCODE_DEFAULT_TOOLCHAIN_OVERRIDE")

private let toolchainDir = env("TOOLCHAIN_DIR")

private let xcrunFindPath: String? = {
  let pathOfXcrun = "/usr/bin/xcrun"

  if !FileManager.default.isExecutableFile(atPath: pathOfXcrun) {
    return nil
  }

  guard let output = Exec.run(pathOfXcrun, "-find", "swift").string else {
    return nil
  }

  var start = output.startIndex
  var end = output.startIndex
  var contentsEnd = output.startIndex
  output.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: start..<start)
  let xcrunFindSwiftPath = String(output[start..<contentsEnd])
  guard xcrunFindSwiftPath.hasSuffix("/usr/bin/swift") else {
    return nil
  }
  let xcrunFindPath = xcrunFindSwiftPath.deleting(lastPathComponents: 3)
  if xcrunFindPath == "/Library/Developer/CommandLineTools" {
    return nil
  }
  return xcrunFindPath
}()

private func appDir(mask: FileManager.SearchPathDomainMask) -> String? {
  NSSearchPathForDirectoriesInDomains(.applicationDirectory, mask, true).first
}

private let applicationsDir = appDir(mask: .systemDomainMask)

private let userApplicationsDir = appDir(mask: .userDomainMask)

extension String {
  fileprivate var toolchainDir: String {
    appending(pathComponent: "Toolchains/XcodeDefault.xctoolchain")
  }

  fileprivate var xcodeDeveloperDir: String {
    appending(pathComponent: "Xcode.app/Contents/Developer")
  }

  fileprivate var xcodeBetaDeveloperDir: String {
    appending(pathComponent: "Xcode-beta.app/Contents/Developer")
  }

  fileprivate var usrLibDir: String {
    appending(pathComponent: "/usr/lib")
  }
}
