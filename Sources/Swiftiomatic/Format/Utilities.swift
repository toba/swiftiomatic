// Utility extensions extracted from SwiftFormat's Arguments.swift
// Original: Copyright 2018 Nick Lockwood (MIT License)

import Foundation

extension Array where Element: Equatable {
    func formattedList(default defaultValue: Element? = nil) -> String
        where Element: RawRepresentable, Element.RawValue: Equatable
    {
        map(\.rawValue).formattedList(default: defaultValue?.rawValue)
    }

    func formattedList(default: Element? = nil) -> String {
        if let `default` {
            assert(contains(where: { $0 == `default` }))
        }
        let options: [String] = compactMap {
            if "\($0)" == "default" {
                return nil
            } else if $0 == `default` {
                return "\"\($0)\" (default)"
            } else {
                return "\"\($0)\""
            }
        }
        return options.formattedList(lastSeparator: "or")
    }
}

extension Array where Element: StringProtocol {
    func formattedList(lastSeparator: String) -> String {
        switch count {
        case 0:
            return ""
        case 1:
            return String(self[0])
        case 2:
            return "\(self[0]) \(lastSeparator) \(self[1])"
        default:
            return "\(dropLast().joined(separator: ", ")) \(lastSeparator) \(last!)"
        }
    }
}

extension String {
    func bestMatch(in options: [String]) -> String? {
        let matches = bestMatches(in: options)
        guard let best = matches.first else {
            return nil
        }
        if matches.count > 1, editDistance(from: matches[1]) == editDistance(from: best) {
            return nil
        }
        return best
    }

    func bestMatches(in options: [String]) -> [String] {
        let lowercaseQuery = lowercased()
        return
            options
                .compactMap { option -> (String, distance: Int, commonPrefix: Int)? in
                    let lowercaseOption = option.lowercased()
                    let distance = lowercaseOption.editDistance(from: lowercaseQuery)
                    let commonPrefix = lowercaseOption.commonPrefix(with: lowercaseQuery)
                    if commonPrefix.isEmpty, distance > lowercaseQuery.count / 2 {
                        return nil
                    }
                    return (option, distance, commonPrefix.count)
                }
                .sorted {
                    if $0.distance == $1.distance {
                        return $0.commonPrefix > $1.commonPrefix
                    }
                    return $0.distance < $1.distance
                }
                .map(\.0)
    }

    func editDistance(from other: String) -> Int {
        let lhs = Array(self)
        let rhs = Array(other)
        var dist = [[Int]]()
        for i in stride(from: 0, through: lhs.count, by: 1) {
            dist.append([i])
        }
        for j in stride(from: 1, through: rhs.count, by: 1) {
            dist[0].append(j)
        }
        for i in stride(from: 1, through: lhs.count, by: 1) {
            for j in stride(from: 1, through: rhs.count, by: 1) {
                if lhs[i - 1] == rhs[j - 1] {
                    dist[i].append(dist[i - 1][j - 1])
                } else {
                    dist[i].append(
                        Swift.min(
                            dist[i - 1][j] + 1,
                            dist[i][j - 1] + 1,
                            dist[i - 1][j - 1] + 1
                        )
                    )
                }
                if i > 1, j > 1, lhs[i - 1] == rhs[j - 2], lhs[i - 2] == rhs[j - 1] {
                    dist[i][j] = Swift.min(dist[i][j], dist[i - 2][j - 2] + 1)
                }
            }
        }
        return dist[lhs.count][rhs.count]
    }
}

/// Parse a comma-delimited list of items
func parseCommaDelimitedList(_ string: String) -> [String] {
    string.components(separatedBy: ",").compactMap {
        let item = $0.trimmingCharacters(in: .whitespacesAndNewlines)
        return item.isEmpty ? nil : item
    }
}
