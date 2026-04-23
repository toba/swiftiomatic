//
//  TriviaPiece+Convenience.swift
//  swiftiomatic
//
//  Created by Jason Abbott on 4/19/26.
//

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

extension TriviaPiece {
    /// Whether this piece is a doc comment (`///` or `/** ... */`).
    var isDocComment: Bool {
        switch self {
            case .docLineComment, .docBlockComment: return true
            default: return false
        }
    }

    /// True if the trivia piece is unexpected text.
    var isUnexpectedText: Bool {
        switch self {
            case .unexpectedText: return true
            default: return false
        }
    }

}
