import Dispatch

extension Array {
    /// Group the elements in this array into a dictionary, keyed by applying the specified `transform`.
    /// Elements for which the `transform` returns a `nil` key are removed.
    ///
    /// - parameter transform: The transformation function to extract an element to its group key,
    ///                        or exclude the element.
    ///
    /// - returns: The elements grouped by applying the specified transformation.
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

    /// Same as `filterGroup`, but spreads the work in the `transform` block in parallel using GCD's
    /// `concurrentPerform`.
    ///
    /// - parameter transform: The transformation function to extract an element to its group key,
    ///                        or exclude the element.
    ///
    /// - returns: The elements grouped by applying the specified transformation.
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

    /// Returns the elements failing the `belongsInSecondPartition` test, followed by the elements passing the
    /// `belongsInSecondPartition` test.
    ///
    /// - parameter belongsInSecondPartition: The test function to determine if the element should be in the second
    ///                                       partition.
    ///
    /// - returns: The elements failing the `belongsInSecondPartition` test, followed by the elements passing the
    ///            `belongsInSecondPartition` test.
    func partitioned(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> (
        first: ArraySlice<Element>, second: ArraySlice<Element>,
    ) {
        var copy = self
        let pivot = try copy.partition(by: belongsInSecondPartition)
        return (copy[0 ..< pivot], copy[pivot ..< count])
    }

    /// Same as `flatMap` but spreads the work in the `transform` block in parallel using GCD's `concurrentPerform`.
    ///
    /// - parameter transform: The transformation to apply to each element.
    ///
    /// - returns: The result of applying `transform` on every element and flattening the results.
    func parallelFlatMap<T>(transform: @Sendable (Element) -> [T]) -> [T] {
        parallelMap(transform: transform).flatMap(\.self)
    }

    /// Same as `compactMap` but spreads the work in the `transform` block in parallel using GCD's `concurrentPerform`.
    ///
    /// - parameter transform: The transformation to apply to each element.
    ///
    /// - returns: The result of applying `transform` on every element and discarding the `nil` ones.
    func parallelCompactMap<T>(transform: @Sendable (Element) -> T?) -> [T] {
        parallelMap(transform: transform).compactMap(\.self)
    }

    /// Same as `map` but spreads the work in the `transform` block in parallel using GCD's `concurrentPerform`.
    ///
    /// - parameter transform: The transformation to apply to each element.
    ///
    /// - returns: The result of applying `transform` on every element.
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
