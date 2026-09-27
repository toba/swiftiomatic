extension String {
    /// Tells if the UTF-8 bytes of the string hold the bytes of `literal` .
    ///
    /// The search compares bytes, not characters, and builds no new `String` . Use it as a fast
    /// precheck before a syntax walk that looks for the same text.
    func containsBytes(_ literal: StaticString) -> Bool {
        literal.withUTF8Buffer { needle in
            guard let first = needle.first else { return true }
            let search = { (haystack: UnsafeBufferPointer<UInt8>) -> Bool in
                guard haystack.count >= needle.count else { return false }
                var index = 0
                let last = haystack.count - needle.count
                while index <= last {
                    if haystack[index] == first,
                       UnsafeBufferPointer(rebasing: haystack[index..<index + needle.count])
                           .elementsEqual(needle)
                    {
                        return true
                    }
                    index += 1
                }
                return false
            }
            if let found = utf8.withContiguousStorageIfAvailable(search) { return found }
            var copy = self
            return copy.withUTF8(search)
        }
    }
}
