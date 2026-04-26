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

/// Advanced options that are useful when debugging and developing the formatter, but are otherwise
/// not meant for general use.
package struct DebugOptions: OptionSet, Sendable {

    /// Disables the pretty-printer pass entirely, executing only the syntax-transforming rules in the
    /// pipeline.
    package static let disablePrettyPrint = DebugOptions(rawValue: 1 << 0)

    /// Dumps a verbose representation of the raw pretty-printer token stream.
    package static let dumpTokenStream = DebugOptions(rawValue: 1 << 1)

    /// Routes formatting through `MultiPassRewritePipeline` instead of the legacy
    /// `RewritePipeline`. While the multi-pass migration is in progress (issues
    /// `qm5-qyp`, `ain-794`, `7x2-5eg`) the new pipeline must produce byte-identical
    /// output to the old one — verified by the golden-corpus harness (`m82-uu9`). Once
    /// every rule is classified and the manifest stabilizes, the legacy pipeline is
    /// removed and this flag goes with it.
    package static let useMultiPassPipeline = DebugOptions(rawValue: 1 << 2)

    package let rawValue: Int

    package init(rawValue: Int) { self.rawValue = rawValue }

    /// Inserts or removes the given element from the option set, based on the value of `enabled`.
    package mutating func set(_ element: Element, enabled: Bool) {
        if enabled { insert(element) } else { remove(element) }
    }
}
