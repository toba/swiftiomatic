import Foundation

/// A unit of Swift source code, either on disk or in memory.
public final class SwiftSource: Sendable {
    /// The underlying SourceKit file.
    let file: File
    /// The associated unique identifier for this file.
    let id: UUID
    /// Whether or not this is a file generated for testing purposes.
    let isTestFile: Bool
    /// A file is virtual if it is not backed by a filesystem path.
    let isVirtual: Bool

    /// Creates a `SwiftSource` with a SourceKit `File`.
    ///
    /// - Parameters:
    ///   - file: A file from the vendored SourceKit layer.
    ///   - isTestFile: Mark the file as being generated for testing purposes only.
    ///   - isVirtual: Mark the file as virtual (in-memory).
    init(file: File, isTestFile: Bool = false, isVirtual: Bool = false) {
        self.file = file
        id = UUID()
        self.isTestFile = isTestFile
        self.isVirtual = isVirtual
    }

    /// Creates a `SwiftSource` by specifying its path on disk.
    /// Fails if the file does not exist.
    ///
    /// - Parameters:
    ///   - path: The path to a file on disk. Relative and absolute paths supported.
    ///   - isTestFile: Mark the file as being generated for testing purposes only.
    public convenience init?(path: String, isTestFile: Bool = false) {
        guard let file = File(path: path) else { return nil }
        self.init(file: file, isTestFile: isTestFile)
    }

    /// Creates a `SwiftSource` by specifying its path on disk. Unlike the  `SwiftSource(path:)` initializer, this
    /// one does not read its contents immediately, but rather traps at runtime when attempting to access its contents.
    ///
    /// - Parameters:
    ///   - path: The path to a file on disk. Relative and absolute paths supported.
    convenience init(pathDeferringReading path: String) {
        self.init(file: File(pathDeferringReading: path))
    }

    /// Creates a `SwiftSource` that is not backed by a file on disk by specifying its contents.
    ///
    /// - Parameters:
    ///   - contents: The contents of the file.
    ///   - isTestFile: Mark the file as being generated for testing purposes only.
    convenience init(contents: String, isTestFile: Bool = false) {
        self.init(file: File(contents: contents), isTestFile: isTestFile, isVirtual: true)
    }

    /// The path on disk for this file.
    var path: String? {
        file.path
    }

    /// The file's contents.
    var contents: String {
        file.contents
    }

    /// A string view into the contents of this file optimized for string manipulation operations.
    var stringView: StringView {
        file.stringView
    }

    /// The parsed lines for this file's contents.
    var lines: [Line] {
        file.lines
    }
}

// MARK: - Hashable Conformance

extension SwiftSource: Equatable, Hashable {
    public static func == (lhs: SwiftSource, rhs: SwiftSource) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
