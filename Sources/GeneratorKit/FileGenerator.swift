//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

/// Common behavior used to generate source files.
package protocol FileGenerator {
    /// Generates the file content as a String.
    func generateContent() -> String
}

private struct FailedToCreateFileError: Error {
    let url: URL
}

extension FileGenerator {
    /// Generates a file at the given URL, skipping the write when
    /// the existing content is already up to date.
    package func generateFile(at url: URL) throws {
        let content = generateContent()
        if let existing = try? String(contentsOf: url, encoding: .utf8),
           existing == content { return }

        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}
