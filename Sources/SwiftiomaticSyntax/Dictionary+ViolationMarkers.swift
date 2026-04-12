extension Dictionary where Key == Example {
  /// Returns a copy with violation markers (`↓`) stripped from every ``Example`` key
  package func removingViolationMarkers() -> [Key: Value] {
    Dictionary(
      uniqueKeysWithValues: map { key, value in
        (key.removingViolationMarkers(), value)
      },
    )
  }
}
