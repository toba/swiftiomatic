// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt
// Pruned: removed process(), parseDeclaration(), XML parsing, doc generation.
// Kept: init variants, path, contents, stringView, lines, clearCaches().

import Foundation
import SourceKitC
import Synchronization

/// Represents a source file.
final class File: Sendable {
    /// File path. Nil if initialized directly with `File(contents:)`.
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

    func clearCaches() {
        state.withLock { s in
            s.contents = nil
            s.stringView = nil
        }
    }

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

    var lines: [Line] {
        stringView.lines
    }

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

    init(pathDeferringReading path: String) {
        self.path = path.absolutePathRepresentation()
        state = Mutex(FileState())
    }

    init(contents: String) {
        path = nil
        state = Mutex(FileState(contents: contents))
    }
}
