struct NSLocalizedStringRequireBundleConfiguration: RuleConfiguration {
    let id = "nslocalizedstring_require_bundle"
    let name = "NSLocalizedString Require Bundle"
    let summary = "Calls to NSLocalizedString should specify the bundle which contains the strings file"
    let isOptIn = true
}
