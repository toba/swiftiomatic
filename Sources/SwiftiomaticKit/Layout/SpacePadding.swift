//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Licensed under Apache License v2.0 with Runtime Library Exception
//
//===----------------------------------------------------------------------===//

/// Cached strings of spaces for common widths to avoid `String(repeating:count:)` allocations on
/// hot paths in the layout writer (per-line indentation, pre-token padding, verbatim leading
/// whitespace).
enum SpacePadding {
    private static let cache: [String] = (0...64).map { String(repeating: " ", count: $0) }

    @inline(__always)
    static func spaces(_ count: Int) -> String {
        if count < 0 {
            ""
        } else if count < cache.count {
            cache[count]
        } else {
            String(repeating: " ", count: count)
        }
    }
}
