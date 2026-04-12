extension Collection {
  /// Whether this collection has one or more elements
  package var isNotEmpty: Bool {
    !isEmpty
  }

  /// The sole element if the collection contains exactly one, otherwise `nil`
  package var onlyElement: Element? {
    count == 1 ? first : nil
  }
}
