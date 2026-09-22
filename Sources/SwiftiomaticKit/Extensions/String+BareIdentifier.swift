extension String {
    /// Whether the string is a valid Swift identifier that needs no backticks.
    ///
    /// The first scalar has to start an identifier, and every later scalar has to continue one.
    /// An underscore is allowed in both positions. A string carrying a space, an operator
    /// character, or any other scalar outside those classes needs backticks, so it reports
    /// `false` .
    var isBareIdentifier: Bool {
        guard let first = unicodeScalars.first,
              first == "_" || first.properties.isXIDStart else { return false }
        return unicodeScalars.dropFirst().allSatisfy {
            $0 == "_" || $0.properties.isXIDContinue
        }
    }
}
