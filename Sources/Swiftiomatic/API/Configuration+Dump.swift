//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

extension Configuration {
  /// The URL of the JSON schema hosted on GitHub.
  public static let schemaURL =
    "https://raw.githubusercontent.com/toba/swiftiomatic/refs/heads/main/swiftiomatic.schema.json"

  /// Return the configuration as a JSON string with a `$schema` reference.
  public func asJsonString() throws(SwiftiomaticError) -> String {
    let data: Data

    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      data = try encoder.encode(self)
    } catch {
      throw SwiftiomaticError.configurationDumpFailed("\(error)")
    }

    guard var jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw SwiftiomaticError.configurationDumpFailed("The JSON was not a valid object")
    }

    jsonObject["$schema"] = Self.schemaURL

    guard
      let merged = try? JSONSerialization.data(
        withJSONObject: jsonObject,
        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
      ),
      let jsonString = String(data: merged, encoding: .utf8)
    else {
      throw SwiftiomaticError.configurationDumpFailed("The JSON was not valid UTF-8")
    }

    return jsonString
  }
}
