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

/// Functions that return `()` or `Void` should omit the return signature.
///
/// Lint: Function declarations that explicitly return `()` or `Void` will yield a lint error.
///
/// Rewrite: Function declarations with explicit returns of `()` or `Void` will have their return
///         signature stripped.
final class NoVoidReturnOnFunctionSignature: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .types }
}
