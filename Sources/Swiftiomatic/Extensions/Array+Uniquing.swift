extension Array where Element: Hashable {
  /// The elements in this array, discarding duplicates after the first one.
  /// Order-preserving. O(n) via `Set` membership checks.
  var unique: [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}

extension Array where Element: Equatable {
  /// The elements in this array, discarding duplicates after the first one.
  /// Order-preserving. O(n²) — prefer the `Hashable`-constrained overload when possible.
  @_disfavoredOverload
  var unique: [Element] {
    var uniqueValues = [Element]()
    for item in self where !uniqueValues.contains(item) {
      uniqueValues.append(item)
    }
    return uniqueValues
  }
}

// MARK: - SourceKit bridging (Any is required at the ObjC boundary)

extension Array where Element: Hashable {
  /// Coerces a SourceKit response value into an array.
  ///
  /// Accepts `[Element]`, `Set<Element>`, or a single `Element` wrapped in `Any?`.
  /// The `Any` parameter is intentional — SourceKit returns untyped dictionaries
  /// (`[String: SourceKitValue]`) and values must be downcast at the boundary.
  static func array(of obj: Any?) -> [Element]? {
    if let array = obj as? [Element] {
      return array
    }
    if let set = obj as? Set<Element> {
      return Array(set)
    }
    if let obj = obj as? Element {
      return [obj]
    }
    return nil
  }
}

extension Array {
  /// Coerces a SourceKit response value into an array.
  ///
  /// Accepts `[Element]` or a single `Element` wrapped in `Any?`.
  /// The `Any` parameter is intentional — SourceKit returns untyped dictionaries
  /// (`[String: SourceKitValue]`) and values must be downcast at the boundary.
  static func array(of obj: Any?) -> [Element]? {
    if let array = obj as? [Element] {
      return array
    }
    if let obj = obj as? Element {
      return [obj]
    }
    return nil
  }
}
