// Vendored from SourceKitten (MIT) — see LICENSES/SourceKitten-MIT.txt
// Pruned: removed process(), parseDeclaration(), XML parsing, doc generation.
// Kept: init variants, path, contents, stringView, lines, clearCaches().

import Dispatch
import Foundation
import SourceKitC

/// Represents a source file.
final class File: @unchecked Sendable {
    /// File path. Nil if initialized directly with `File(contents:)`.
    let path: String?
    /// File contents.
    var contents: String {
        get {
            _contentsQueue.sync {
                if _contents == nil {
                    do {
                        _contents = try String(contentsOfFile: path!, encoding: .utf8)
                    } catch {
                        fputs("Could not read contents of `\(path!)`\n", stderr)
                        _contents = ""
                    }
                }
            }
            return _contents!
        }
        set {
            _contentsQueue.sync {
                _contents = newValue
                _stringViewQueue.sync {
                    _stringView = nil
                }
            }
        }
    }

    func clearCaches() {
        _contentsQueue.sync {
            _contents = nil
            _stringViewQueue.sync {
                _stringView = nil
            }
        }
    }

    var stringView: StringView {
        _stringViewQueue.sync {
            if _stringView == nil {
                _stringView = StringView(contents)
            }
        }
        return _stringView!
    }

    var lines: [Line] {
        stringView.lines
    }

    private var _contents: String?
    private var _stringView: StringView?
    private let _contentsQueue = DispatchQueue(label: "com.swiftiomatic.file.contents")
    private let _stringViewQueue = DispatchQueue(label: "com.swiftiomatic.file.stringView")

    init?(path: String) {
        self.path = path.bridge().absolutePathRepresentation()
        do {
            _contents = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            fputs("Could not read contents of `\(path)`\n", stderr)
            return nil
        }
    }

    init(pathDeferringReading path: String) {
        self.path = path.bridge().absolutePathRepresentation()
    }

    init(contents: String) {
        path = nil
        _contents = contents
    }
}
