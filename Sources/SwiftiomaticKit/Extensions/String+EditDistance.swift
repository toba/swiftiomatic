// Utility extensions extracted from SwiftFormat's Arguments.swift
// Original: Copyright 2018 Nick Lockwood (MIT License)

import Foundation

extension Array where Element: Equatable {
  /// Formats raw-representable values as a human-readable list with a default annotation
  ///
  /// - Parameters:
  ///   - defaultValue: The element to mark as `"(default)"` in the output, if any.
  func formattedList(default defaultValue: Element? = nil) -> String
  where Element: RawRepresentable, Element.RawValue: Equatable {
    map(\.rawValue).formattedList(default: defaultValue?.rawValue)
  }

  /// Formats equatable values as a human-readable list with a default annotation
  ///
  /// - Parameters:
  ///   - default: The element to mark as `"(default)"` in the output, if any.
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
  /// Joins elements with commas and a final separator word (e.g. `"or"`, `"and"`)
  ///
  /// - Parameters:
  ///   - lastSeparator: The word placed before the last element (e.g. `"or"`).
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
  /// Returns the single closest match from `options`, or `nil` if ambiguous or no match is close enough
  ///
  /// - Parameters:
  ///   - options: Candidate strings to match against.
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

  /// Returns candidate strings sorted by edit distance, filtering out distant mismatches
  ///
  /// - Parameters:
  ///   - options: Candidate strings to rank against this string.
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

  /// Computes the Damerau-Levenshtein edit distance to another string
  ///
  /// - Parameters:
  ///   - other: The string to compare against.
  func editDistance(from other: String) -> Int {
    let lhs = Array(self)
    let rhs = Array(other)
    let rows = lhs.count + 1
    let cols = rhs.count + 1
    var dist = Array(repeating: Array(repeating: 0, count: cols), count: rows)
    for i in 0..<rows { dist[i][0] = i }
    for j in 0..<cols { dist[0][j] = j }
    for i in 1..<rows {
      for j in 1..<cols {
        if lhs[i - 1] == rhs[j - 1] {
          dist[i][j] = dist[i - 1][j - 1]
        } else {
          dist[i][j] = Swift.min(
            dist[i - 1][j] + 1,
            dist[i][j - 1] + 1,
            dist[i - 1][j - 1] + 1,
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

extension String {
  /// Splits on commas and trims whitespace, discarding empty items.
  var commaDelimitedItems: [String] {
    components(separatedBy: ",").compactMap {
      let item = $0.trimmingCharacters(in: .whitespacesAndNewlines)
      return item.isEmpty ? nil : item
    }
  }
}

/// Legacy free-function wrapper -- prefer ``String/commaDelimitedItems``
///
/// - Parameters:
///   - string: A comma-separated string to split.
func parseCommaDelimitedList(_ string: String) -> [String] {
  string.commaDelimitedItems
}
