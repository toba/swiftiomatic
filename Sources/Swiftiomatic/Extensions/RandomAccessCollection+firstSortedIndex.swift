extension RandomAccessCollection where Index == Int {
    /// Returns the first index whose element satisfies `predicate` in a sorted collection
    ///
    /// The collection must be partitioned so that all elements returning `false`
    /// precede all elements returning `true`. If it is not sorted this way, the
    /// result is undefined.
    ///
    /// ```swift
    /// let values = [1, 2, 3, 4, 5]
    /// let idx = values.firstIndexAssumingSorted(where: { $0 > 3 })
    /// // false, false, false, true, true
    /// //                      ^
    /// // idx == 3
    /// ```
    ///
    /// - Parameters:
    ///   - predicate: A closure that takes an element and returns `true` when the
    ///     element is at or past the desired partition point.
    ///
    /// - Returns: The index of the first element for which `predicate` returns
    ///   `true`, or `nil` if no elements satisfy the predicate.
    ///
    /// - Complexity: O(log *n*), where *n* is the length of the collection.
    @inlinable
    func firstIndexAssumingSorted(where predicate: (Self.Element) throws -> Bool) rethrows -> Int? {
        // Predicate should divide a collection to two pairs of values
        // "bad" values for which predicate returns `false`
        // "good" values for which predicate return `true`

        // false false false false false true true true
        //                               ^
        // The idea is to get _first_ index which for which the predicate returns `true`

        let lastIndex = count

        // The index that represents where bad values start
        var badIndex = -1

        // The index that represents where good values start
        var goodIndex = lastIndex
        var midIndex = (badIndex + goodIndex) / 2

        while badIndex + 1 < goodIndex {
            if try predicate(self[midIndex]) {
                goodIndex = midIndex
            } else {
                badIndex = midIndex
            }
            midIndex = (badIndex + goodIndex) / 2
        }

        // We're out of bounds, no good items in array
        if midIndex == lastIndex {
            return nil
        }
        return goodIndex
    }
}
