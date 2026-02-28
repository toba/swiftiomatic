extension Array where Element: Equatable {
  /// The elements in this array, discarding duplicates after the first one.
  /// Order-preserving.
  var unique: [Element] {
    var uniqueValues = [Element]()
    for item in self where !uniqueValues.contains(item) {
      uniqueValues.append(item)
    }
    return uniqueValues
  }
}

extension Array where Element: Hashable {
  /// Produces an array containing the passed `obj` value.
  /// If `obj` is an array already, return it.
  /// If `obj` is a set, copy its elements to a new array.
  /// If `obj` is a value of type `Element`, return a single-item array containing it.
  ///
  /// This overload exists separately from the unconstrained version because
  /// Set conversion requires Hashable conformance.
  ///
  /// - parameter obj: The input.
  ///
  /// - returns: The produced array.
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
  /// Produces an array containing the passed `obj` value.
  /// If `obj` is an array already, return it.
  /// If `obj` is a value of type `Element`, return a single-item array containing it.
  ///
  /// - parameter obj: The input.
  ///
  /// - returns: The produced array.
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
