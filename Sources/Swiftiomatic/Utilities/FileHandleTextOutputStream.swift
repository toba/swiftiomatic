//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

/// Wraps a `FileHandle` so that it can be used by APIs that take a `TextOutputStream` -conforming
/// type as an input.
struct FileHandleTextOutputStream: TextOutputStream {
    /// The underlying file handle to which the text will be written.
    private var fileHandle: FileHandle

    /// Creates a new output stream that writes to the given file handle.
    init(_ fileHandle: FileHandle) { self.fileHandle = fileHandle }

    /// Writes the UTF-8 bytes of the string. A native string gives its bytes in place, so the
    /// write makes no `Data` copy.
    func write(_ string: String) {
        var string = string
        string.withUTF8 { bytes in
            guard !bytes.isEmpty else { return }
            // `write(_: Data)` raised an Objective-C exception on failure. That stopped the
            // process. `write(contentsOf:)` throws instead, and a closed pipe is not a reason to
            // stop, so the error is ignored.
            try? fileHandle.write(contentsOf: UnsafeRawBufferPointer(bytes))
        }
    }
}
