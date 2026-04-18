import Foundation
import SwiftSyntax

/// The part of a node where an emitted finding should be anchored.
enum FindingAnchor {
    /// The finding is anchored at the beginning of the node's actual content, skipping any leading
    /// trivia.
    case start

    /// The finding is anchored at the beginning of the trivia piece at the given index in the node's
    /// leading trivia.
    case leadingTrivia(Trivia.Index)

    /// The finding is anchored at the beginning of the trivia piece at the given index in the node's
    /// trailing trivia.
    case trailingTrivia(Trivia.Index)
}
