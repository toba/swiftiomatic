// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors Licensed under Apache License
// v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information See https://swift.org/CONTRIBUTORS.txt
// for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import Foundation
@_exported import enum ConfigurationKit.KeySortOrder

package extension Configuration {
    /// Return the configuration as a JSON string with a `$schema` reference.
    ///
    /// Rule objects that fit within 100 columns are printed on a single line.
    func asJSONString(
        sortBy order: KeySortOrder = .length
    ) throws(SwiftiomaticError) -> String {
        // Encode to JSONValue, then serialize with key ordering. $schema is emitted by encode(to:),
        // pinned to the top by the serializer.
        let jsonValue: JSONValue

        do {
            let data = try JSONEncoder().encode(self)
            jsonValue = try JSONDecoder().decode(JSONValue.self, from: data)
        } catch {
            throw SwiftiomaticError.configurationDumpFailed("\(error)")
        }

        var jsonString = jsonValue.serialize(sortBy: order)
        jsonString = JSONCompaction.compactSmallObjects(
            in: jsonString, maxWidth: 100, requiringQuotedKey: true)

        return jsonString
    }
}
