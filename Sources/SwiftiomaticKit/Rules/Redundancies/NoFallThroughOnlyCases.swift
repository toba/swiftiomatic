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

import SwiftSyntax

/// Cases that contain only the `fallthrough` statement are forbidden.
///
/// Lint: Cases containing only the `fallthrough` statement yield a lint error.
///
/// Rewrite: The fall-through `case` is added as a prefix to the next case unless the next case is
///         `default`; in that case, the fallthrough `case` is deleted.
final class NoFallThroughOnlyCases: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    // Diagnose against the pre-traversal node so finding source locations
    // are accurate. The compact-pipeline rewrite (in
    // `Rewrites/Stmts/SwitchCaseList.swift::applyNoFallThroughOnlyCases`)
    // handles the rewrite without diagnose.
    static func willEnter(_ node: SwitchCaseListSyntax, context: Context) {
        noFallThroughOnlyCasesDiagnoseInPlace(node, context: context)
    }

}

extension TriviaPiece {
    /// Returns whether this piece is any type of comment.
    var isComment: Bool {
        switch self {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                true
            default:
                false
        }
    }

    /// Returns whether this piece is a number of newlines.
    var isNewline: Bool {
        switch self {
            case .newlines:
                true
            default:
                false
        }
    }
}

extension Finding.Message {
    fileprivate static var collapseCase: Finding.Message {
        "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"
    }
}
