struct PreferAssetSymbolsConfiguration: RuleConfiguration {
    let id = "prefer_asset_symbols"
    let name = "Prefer Asset Symbols"
    let summary = "Prefer using asset symbols over string-based image initialization"
    let isOptIn = true
    var nonTriggeringExamples: [Example] {
        [
              // UIKit - using asset symbols
              Example("UIImage(resource: .someImage)"),
              Example("UIImage(systemName: \"trash\")"),
              // SwiftUI - using asset symbols
              Example("Image(.someImage)"),
              Example("Image(systemName: \"trash\")"),
              // Dynamic strings (variables or interpolated)
              Example("UIImage(named: imageName)"),
              Example("UIImage(named: \"image_\\(suffix)\")"),
              Example("Image(imageName)"),
              Example("Image(\"image_\\(suffix)\")"),
            ]
    }
    var triggeringExamples: [Example] {
        [
              // UIKit examples
              Example("↓UIImage(named: \"some_image\")"),
              Example("↓UIImage(named: \"some image\")"),
              Example("↓UIImage.init(named: \"someImage\")"),
              // UIKit with bundle parameters
              Example("↓UIImage(named: \"someImage\", in: Bundle.main, compatibleWith: nil)"),
              Example("↓UIImage(named: \"someImage\", in: .main)"),
              // SwiftUI examples
              Example("↓Image(\"some_image\")"),
              Example("↓Image(\"some image\")"),
              Example("↓Image.init(\"someImage\")"),
              // SwiftUI with bundle parameters
              Example("↓Image(\"someImage\", bundle: Bundle.main)"),
              Example("↓Image(\"someImage\", bundle: .main)"),
            ]
    }
    let rationale: String? = """
      `UIKit.UIImage(named:)` and `SwiftUI.Image(_:)` bear the risk of bugs due to typos in their string \
      arguments. Since Xcode 15, Xcode generates codes for images in the Asset Catalog. Usage of these codes \
      and system icons from SF Symbols avoid typos and allow for compile-time checking.
      """
}
