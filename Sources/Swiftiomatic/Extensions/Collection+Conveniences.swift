extension Collection {
  /// Whether this collection has one or more element.
  var isNotEmpty: Bool {
    !isEmpty
  }

  /// Get the only element in the collection.
  ///
  /// If the collection is empty or contains more than one element the result will be `nil`.
  var onlyElement: Element? {
    count == 1 ? first : nil
  }
}
