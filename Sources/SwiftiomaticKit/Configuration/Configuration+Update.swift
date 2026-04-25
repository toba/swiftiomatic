import Foundation

extension Configuration {
    /// A diff between a configuration file and the current rule registry.
    package struct UpdateDiff: Sendable, Equatable {
        /// Qualified keys to add (with default values).
        package var toAdd: [String]
        /// Qualified or bare keys for unknown rules to remove.
        package var toRemove: [String]
        /// Rules found in the wrong location, with their existing values to preserve.
        package var misplaced: [Misplaced]

        package struct Misplaced: Sendable, Equatable {
            /// The qualified key where the rule was found, e.g. `wrap.preferIsEmpty`.
            /// For ungrouped rules placed at root, this is the bare key.
            package var foundAt: String
            /// The canonical qualified key for the rule, e.g. `idioms.preferIsEmpty`.
            package var correctAt: String
            /// The user's existing value, to be preserved on relocation.
            package var value: JSONValue
        }

        package var hasChanges: Bool {
            !toAdd.isEmpty || !toRemove.isEmpty || !misplaced.isEmpty
        }
    }

    /// Computes the diff between a parsed JSON config and the current rule registry.
    package static func computeUpdate(for root: [String: JSONValue]) -> UpdateDiff {
        let validKeys = allRuleQualifiedKeys
        let shortToQualified = qualifiedKeyByShortKey
        let metaKeys = allSettingAndMetaKeys
        let groupNames = groupKeyNames

        var toRemove: [String] = []
        var misplaced: [UpdateDiff.Misplaced] = []
        var foundCorrectKeys = Set<String>()

        func classify(shortKey: String, foundAt: String, value: JSONValue) {
            // If the rule exists at exactly this qualified key, it's correctly placed.
            // (Handles short-key collisions across groups, e.g. `sort.switchCases` and
            // `indentation.switchCases`.)
            if validKeys.contains(foundAt) {
                foundCorrectKeys.insert(foundAt)
                return
            }
            if let canonical = shortToQualified[shortKey] {
                misplaced.append(.init(foundAt: foundAt, correctAt: canonical, value: value))
            } else {
                toRemove.append(foundAt)
            }
        }

        for (key, value) in root {
            // Group dispatch comes first — a setting key that collides with a group name
            // (e.g. `blankLines`) at the root must be treated as the group, not a setting.
            if groupNames.contains(key), case .object(let groupDict) = value,
                let groupKey = ConfigurationGroup.Key(rawValue: key)
            {
                let groupSettingKeys = settingKeys(inGroup: groupKey)
                for (childKey, childValue) in groupDict where !groupSettingKeys.contains(childKey) {
                    classify(
                        shortKey: childKey,
                        foundAt: "\(key).\(childKey)",
                        value: childValue
                    )
                }
                continue
            }
            if metaKeys.contains(key) { continue }
            classify(shortKey: key, foundAt: key, value: value)
        }

        let foundOrMisplacedCorrect = foundCorrectKeys.union(misplaced.map(\.correctAt))
        let toAdd = validKeys.subtracting(foundOrMisplacedCorrect).sorted()

        return UpdateDiff(
            toAdd: toAdd,
            toRemove: toRemove.sorted(),
            misplaced: misplaced.sorted { $0.foundAt < $1.foundAt }
        )
    }

    /// Applies a diff to a JSON config dict in place. Default values for added rules come
    /// from `defaults` (typically a freshly-encoded default `Configuration`).
    package static func apply(
        _ diff: UpdateDiff,
        to root: inout [String: JSONValue],
        defaults: [String: JSONValue]
    ) {
        // Misplaced: remove from wrong location, then insert (preserving value) at correct.
        for entry in diff.misplaced {
            removeKey(entry.foundAt, from: &root)
            insertKey(entry.correctAt, value: entry.value, into: &root)
        }

        // Removals: unknown keys.
        for key in diff.toRemove {
            removeKey(key, from: &root)
        }

        // Additions: pull default values from the encoded default Configuration.
        for key in diff.toAdd {
            let value = defaultValue(forQualifiedKey: key, defaults: defaults)
            insertKey(key, value: value, into: &root)
        }
    }

    // MARK: - JSON dict mutations

    private static func removeKey(_ qualifiedKey: String, from root: inout [String: JSONValue]) {
        let (group, name) = qualifiedKey.qualifiedKeyParts
        if let group, case .object(var groupDict) = root[group] {
            groupDict.removeValue(forKey: name)
            root[group] = .object(groupDict)
        } else {
            root.removeValue(forKey: qualifiedKey)
        }
    }

    private static func insertKey(
        _ qualifiedKey: String,
        value: JSONValue,
        into root: inout [String: JSONValue]
    ) {
        let (group, name) = qualifiedKey.qualifiedKeyParts
        if let group {
            if case .object(var groupDict) = root[group] {
                groupDict[name] = value
                root[group] = .object(groupDict)
            } else {
                root[group] = .object([name: value])
            }
        } else {
            root[qualifiedKey] = value
        }
    }

    private static func defaultValue(
        forQualifiedKey key: String,
        defaults: [String: JSONValue]
    ) -> JSONValue {
        let (group, name) = key.qualifiedKeyParts
        if let group, case .object(let groupDict) = defaults[group] {
            return groupDict[name] ?? .object([:])
        }
        if group == nil, let value = defaults[key] {
            return value
        }
        return .object([:])
    }
}
