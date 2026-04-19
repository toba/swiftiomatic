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

import SwiftOperators
import SwiftSyntax

extension Syntax {
    /// Creates a pretty-printable token stream for the provided Syntax node.
    func makeTokenStream(
        configuration: Configuration,
        selection: Selection,
        operatorTable: OperatorTable
    ) -> [Token] {
        let commentsMoved = CommentMovingRewriter(selection: selection).rewrite(self)
        return TokenStream(
            configuration: configuration,
            selection: selection,
            operatorTable: operatorTable
        ).makeStream(from: commentsMoved)
    }
}
