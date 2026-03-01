// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt
// Pruned: removed process(), parseDeclaration(), XML parsing, doc generation.
// Kept: init variants, path, contents, stringView, lines, clearCaches().

import Foundation
import SourceKitC
import Synchronization

/// A Swift source file that lazily reads and caches its contents
///
/// Provides ``StringView``-based access for byte-range operations
/// required by SourceKit responses. Thread-safe via ``Mutex``.
final class File: Sendable {
    /// File path, or `nil` if initialized directly with ``init(contents:)``
    let path: String?

    private struct FileState {
        var contents: String?
        var stringView: StringView?

        mutating func ensureContents(path: String) -> String {
            if let contents { return contents }
            do {
                contents = try String(contentsOfFile: path, encoding: .utf8)
            } catch {
                fputs("Could not read contents of `\(path)`\n", stderr)
                contents = ""
            }
            return contents!
        }
    }

    private let state: Mutex<FileState>

    /// File contents.
    var contents: String {
        get {
            state.withLock { s in
                guard let path else { return s.contents ?? "" }
                return s.ensureContents(path: path)
            }
        }
        set {
            state.withLock { s in
                s.contents = newValue
                s.stringView = nil
            }
        }
    }

    /// Discard cached contents and string view, forcing a re-read on next access
    func clearCaches() {
        state.withLock { s in
            s.contents = nil
            s.stringView = nil
        }
    }

    /// A ``StringView`` over the file contents, lazily created and cached
    var stringView: StringView {
        state.withLock { s in
            if s.stringView == nil {
                guard let path else {
                    let view = StringView(s.contents ?? "")
                    s.stringView = view
                    return view
                }
                let text = s.ensureContents(path: path)
                s.stringView = StringView(text)
            }
            return s.stringView!
        }
    }

    /// The lines of the file, derived from ``stringView``
    var lines: [Line] {
        stringView.lines
    }

    /// Create a file by immediately reading from disk
    ///
    /// Returns `nil` if the file cannot be read.
    ///
    /// - Parameters:
    ///   - path: The file system path to read.
    init?(path: String) {
        self.path = path.absolutePathRepresentation()
        do {
            let contents = try String(contentsOfFile: path, encoding: .utf8)
            state = Mutex(FileState(contents: contents))
        } catch {
            fputs("Could not read contents of `\(path)`\n", stderr)
            return nil
        }
    }

    /// Create a file that defers reading until ``contents`` is first accessed
    ///
    /// - Parameters:
    ///   - path: The file system path to read later.
    init(pathDeferringReading path: String) {
        self.path = path.absolutePathRepresentation()
        state = Mutex(FileState())
    }

    /// Create a file from in-memory contents with no backing path
    ///
    /// - Parameters:
    ///   - contents: The Swift source text.
    init(contents: String) {
        path = nil
        state = Mutex(FileState(contents: contents))
    }
}
