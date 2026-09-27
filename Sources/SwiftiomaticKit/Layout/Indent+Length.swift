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

extension Indent {
    var character: Character {
        switch self {
            case .tabs: "\t"
            case .spaces: " "
        }
    }

    var text: String { .init(repeating: character, count: count) }

    func length(tabWidth: Int) -> Int {
        switch self {
            case let .spaces(count): count
            case let .tabs(count): count * tabWidth
        }
    }
}
