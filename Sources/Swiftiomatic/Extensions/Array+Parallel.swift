import Dispatch

extension Array {
    /// Groups elements into a dictionary by a key extracted via `transform`, discarding `nil` keys
    ///
    /// - Parameters:
    ///   - transform: A closure that returns the group key for an element, or `nil` to exclude it.
    ///
    /// - Returns: The elements grouped by the key returned from `transform`.
    func filterGroup<U: Hashable & Sendable>(by transform: (Element) -> U?) -> [U: [Element]]
        where Element: Sendable
    {
        var result = [U: [Element]]()
        for element in self {
            if let key = transform(element) {
                result[key, default: []].append(element)
            }
        }
        return result
    }

    /// Parallel variant of ``filterGroup(by:)`` using GCD's `concurrentPerform`
    ///
    /// Falls back to the sequential version for arrays with fewer than 16 elements.
    ///
    /// - Parameters:
    ///   - transform: A closure that returns the group key for an element, or `nil` to exclude it.
    ///
    /// - Returns: The elements grouped by the key returned from `transform`.
    func parallelFilterGroup<U: Hashable & Sendable>(by transform: @Sendable (Element) -> U?) -> [U:
        [Element]] where Element: Sendable
    {
        if count < 16 {
            return filterGroup(by: transform)
        }
        let pivot = count / 2
        let results = [
            Array(self[0 ..< pivot]),
            Array(self[pivot...]),
        ].parallelMap { subarray in
            subarray.parallelFilterGroup(by: transform)
        }
        return results[0].merging(results[1], uniquingKeysWith: +)
    }

    /// Splits the array into two slices around a predicate
    ///
    /// Elements that fail `belongsInSecondPartition` appear in `first`;
    /// elements that pass appear in `second`. Relative order within each
    /// partition is **not** preserved (uses the standard library's in-place `partition`).
    ///
    /// - Parameters:
    ///   - belongsInSecondPartition: A closure that returns `true` for elements
    ///     that belong in the second partition.
    ///
    /// - Returns: A named tuple of `(first:, second:)` array slices.
    func partitioned(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> (
        first: ArraySlice<Element>, second: ArraySlice<Element>,
    ) {
        var copy = self
        let pivot = try copy.partition(by: belongsInSecondPartition)
        return (copy[0 ..< pivot], copy[pivot ..< count])
    }

    /// Parallel variant of `flatMap` using GCD's `concurrentPerform`
    ///
    /// - Parameters:
    ///   - transform: The transformation to apply to each element.
    ///
    /// - Returns: The flattened results of applying `transform` to every element.
    func parallelFlatMap<T>(transform: @Sendable (Element) -> [T]) -> [T] {
        parallelMap(transform: transform).flatMap(\.self)
    }

    /// Parallel variant of `compactMap` using GCD's `concurrentPerform`
    ///
    /// - Parameters:
    ///   - transform: The transformation to apply to each element.
    ///
    /// - Returns: The non-`nil` results of applying `transform` to every element.
    func parallelCompactMap<T>(transform: @Sendable (Element) -> T?) -> [T] {
        parallelMap(transform: transform).compactMap(\.self)
    }

    /// Parallel variant of `map` using GCD's `concurrentPerform`
    ///
    /// - Parameters:
    ///   - transform: The transformation to apply to each element.
    ///
    /// - Returns: The results of applying `transform` to every element.
    func parallelMap<T>(transform: @Sendable (Element) -> T) -> [T] {
        var result = ContiguousArray<T?>(repeating: nil, count: count)
        return result.withUnsafeMutableBufferPointer { buffer in
            let buffer = SendableMutableBuffer(buffer: buffer)
            withUnsafeBufferPointer { array in
                let array = SendableBuffer(buffer: array)
                DispatchQueue.concurrentPerform(iterations: buffer.count) { idx in
                    buffer[idx] = transform(array[idx])
                }
            }
            return buffer.data
        }
    }

    private final class SendableMutableBuffer<T>: @unchecked Sendable {
        let buffer: UnsafeMutableBufferPointer<T?>

        init(buffer: UnsafeMutableBufferPointer<T?>) {
            self.buffer = buffer
        }

        var data: [T] {
            buffer.map { $0! }
        }

        var count: Int {
            buffer.count
        }

        subscript(index: Int) -> T {
            get {
                Console.fatalError("Do not call this getter.")
            }
            set(newValue) {
                buffer[index] = newValue
            }
        }
    }

    private final class SendableBuffer<T>: @unchecked Sendable {
        let buffer: UnsafeBufferPointer<T>

        init(buffer: UnsafeBufferPointer<T>) {
            self.buffer = buffer
        }

        subscript(index: Int) -> T {
            buffer[index]
        }
    }
}
