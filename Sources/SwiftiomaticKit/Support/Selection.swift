//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftSyntax

/// The selection as given on the command line - an array of offets and lengths
package enum Selection {
    /// The entire file is selected.
    case infinite

    /// A selection representing the given open ranges of UTF-8 offsets.
    case ranges([Range<AbsolutePosition>])

    /// A selection representing the given closed ranges of line numbers.
    case unresolvedLineRanges([ClosedRange<Int>])

    /// Create a selection from an array of utf8 ranges. An empty array means an infinite selection.
    package init(offsetRanges: [Range<Int>]) {
        if offsetRanges.isEmpty {
            self = .infinite
        } else {
            let ranges = offsetRanges.map {
                AbsolutePosition(
                    utf8Offset: $0.lowerBound
                )..<AbsolutePosition(utf8Offset: $0.upperBound)
            }
            self = .ranges(ranges)
        }
    }

    package init(lineRanges: [ClosedRange<Int>]) {
        if lineRanges.isEmpty {
            self = .infinite
        } else {
            self = .unresolvedLineRanges(lineRanges)
        }
    }

    package func resolved(with converter: SourceLocationConverter) -> Selection {
        switch self {
            case .infinite, .ranges:
                return self
            case .unresolvedLineRanges(let lineRanges):
                let resolvedRanges = lineRanges.map { lineRange in
                    let start = converter.position(ofLine: lineRange.lowerBound, column: 1)
                    let nextLineStart = converter.position(
                        ofLine: lineRange.upperBound + 1, column: 1)
                    if start == nextLineStart {
                        return start..<start
                    }
                    // Subtract 1 from the next line's start offset to get the end of the current line.
                    let end = AbsolutePosition(utf8Offset: nextLineStart.utf8Offset - 1)
                    return start..<end
                }
                return .ranges(resolvedRanges)
        }
    }

    package func contains(_ position: AbsolutePosition) -> Bool {
        switch self {
            case .infinite:
                true
            case .ranges(let ranges):
                ranges.contains { $0.contains(position) }
            case .unresolvedLineRanges:
                fatalError("Must resolve Selection before calling contains")
        }
    }

    package func overlapsOrTouches(_ range: Range<AbsolutePosition>) -> Bool {
        switch self {
            case .infinite:
                return true
            case .ranges(let ranges):
                return ranges.contains { $0.overlapsOrTouches(range) }
            case .unresolvedLineRanges:
                fatalError("Must resolve Selection before calling overlapsOrTouches")
        }
    }
}

// MARK: - Support

extension Syntax {
    /// - Returns: `true` if the node is _completely_ inside any range in the selection
    package func isInsideSelection(_ selection: Selection) -> Bool {
        switch selection {
            case .infinite:
                return true
            case .ranges(let ranges):
                return ranges.contains {
                    $0.lowerBound <= position && endPosition <= $0.upperBound
                }
            case .unresolvedLineRanges:
                fatalError("Must resolve Selection before calling isInsideSelection")
        }
    }
}
