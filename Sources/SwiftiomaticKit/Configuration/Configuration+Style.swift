extension Configuration {
    /// Throws if the configured style is reserved but not yet implemented.
    ///
    /// `roomy` is currently a reserved name only — selecting it fails fast rather
    /// than silently behaving like `compact`. See issue `0ev-1u9`.
    package func validateStyleSupported() throws(SwiftiomaticError) {
        let style = self[StyleSetting.self]
        switch style {
            case .compact: return
            case .roomy: throw .styleNotImplemented(style.rawValue)
        }
    }
}
