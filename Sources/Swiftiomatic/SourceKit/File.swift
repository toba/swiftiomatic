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
    }

    private let state: Mutex<FileState>

    /// File contents.
    var contents: String {
        get {
            state.withLock { s in
                if s.contents == nil {
                    do {
                        s.contents = try String(contentsOfFile: path!, encoding: .utf8)
                    } catch {
                        fputs("Could not read contents of `\(path!)`\n", stderr)
                        s.contents = ""
                    }
                }
                return s.contents!
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
                // Read contents outside stringView init to ensure it's populated
                if s.contents == nil {
                    do {
                        s.contents = try String(contentsOfFile: path!, encoding: .utf8)
                    } catch {
                        fputs("Could not read contents of `\(path!)`\n", stderr)
                        s.contents = ""
                    }
                }
                s.stringView = StringView(s.contents!)
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
