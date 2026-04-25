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

extension DeclModifierListSyntax {
    /// Returns the declaration's access level modifier, if present.
    var accessLevelModifier: DeclModifierSyntax? {
        for modifier in self {
            switch modifier.name.tokenKind {
                case .keyword(.public), .keyword(.private), .keyword(.fileprivate),
                    .keyword(.internal),
                    .keyword(.package):
                    return modifier
                default:
                    continue
            }
        }
        return nil
    }

    /// Returns true if the modifier list contains the given keyword.
    func contains(_ keyword: Keyword) -> Bool {
        contains { $0.name.tokenKind == .keyword(keyword) }
    }

    /// Returns true if the modifier list contains any of the keywords in the given set.
    func contains(anyOf keywords: Set<Keyword>) -> Bool {
        contains {
            switch $0.name.tokenKind {
                case .keyword(let keyword): return keywords.contains(keyword)
                default: return false
            }
        }
    }

    /// Removes any of the modifiers in the given set from the modifier list, mutating it in-place.
    mutating func remove(anyOf keywords: Set<Keyword>) {
        self = filter {
            switch $0.name.tokenKind {
                case .keyword(let keyword): return !keywords.contains(keyword)
                default: return true
            }
        }
    }

    /// Returns a copy of the modifier list with any of the modifiers in the given set removed.
    func removing(anyOf keywords: Set<Keyword>) -> DeclModifierListSyntax {
        filter {
            switch $0.name.tokenKind {
                case .keyword(let keyword): return !keywords.contains(keyword)
                default: return true
            }
        }
    }
}

extension DeclSyntaxProtocol where Self: WithModifiersSyntax {
    /// Removes modifiers matching `keywords` and transfers leading trivia from the first removed
    /// modifier to the next remaining modifier — or to the declaration keyword if no modifiers remain.
    ///
    /// This is the standard pattern for removing access-level or other modifiers while preserving
    /// trivia (comments, whitespace) that was attached to the removed modifier.
    func removingModifiers(
        _ keywords: Set<Keyword>,
        keyword: WritableKeyPath<Self, TokenSyntax>
    ) -> Self {
        guard
            let removedIndex = modifiers.firstIndex(where: {
                if case .keyword(let kw) = $0.name.tokenKind { return keywords.contains(kw) }
                return false
            })
        else { return self }

        let removedModifier = modifiers[removedIndex]
        let removedIsFirst = removedIndex == modifiers.startIndex
        var result = self
        result.modifiers = modifiers.removing(anyOf: keywords)

        if removedIsFirst {
            // Transfer the removed modifier's leading trivia to the next item.
            let savedTrivia = removedModifier.leadingTrivia
            if var firstModifier = result.modifiers.first {
                firstModifier.leadingTrivia = savedTrivia
                result.modifiers[result.modifiers.startIndex] = firstModifier
            } else {
                result[keyPath: keyword].leadingTrivia = savedTrivia
            }
        }
        return result
    }
}
