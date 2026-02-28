extension Dictionary where Key == Example {
  /// Returns a dictionary with SwiftLint violation markers (↓) removed from keys.
  ///
  /// - returns: A new `Dictionary`.
  func removingViolationMarkers() -> [Key: Value] {
    Dictionary(
      uniqueKeysWithValues: map { key, value in
        (key.removingViolationMarkers(), value)
      },
    )
  }
}
