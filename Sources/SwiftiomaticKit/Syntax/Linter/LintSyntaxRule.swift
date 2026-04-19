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
import SwiftSyntax

/// A rule that lints a given file.
class LintSyntaxRule: SyntaxVisitor, SyntaxRule {
    /// The context in which the rule is executed.
    let context: Context

    // class var so subclass overrides dispatch correctly through the vtable
    // when accessed via protocol existentials (any Rule.Type).
    class var key: String {
        let name = String("\(self)".split(separator: ".").last!)
        return name.prefix(1).lowercased() + name.dropFirst()
    }
    class var group: ConfigurationGroup? { nil }
    class var defaultHandling: RuleHandling { .warning }

    /// Creates a new rule in a given context.
    required init(context: Context) {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }
}
