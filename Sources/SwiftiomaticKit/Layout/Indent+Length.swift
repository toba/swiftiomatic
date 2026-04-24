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

    var text: String { String(repeating: character, count: count) }

    func length(tabWidth: Int) -> Int {
        switch self {
            case .spaces(let count): count
            case .tabs(let count): count * tabWidth
        }
    }
}

extension [Indent] {
    func indentation() -> String { map { $0.text }.joined() }

    func length(in configuration: Configuration) -> Int {
        length(tabWidth: configuration[TabWidth.self])
    }

    func length(tabWidth: Int) -> Int { reduce(into: 0) { $0 += $1.length(tabWidth: tabWidth) } }
}
