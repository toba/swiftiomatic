// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "swiftiomatic",
  platforms: [.macOS(.v26)],
  products: [
    .executable(name: "sm", targets: ["sm"]),
    .library(name: "Swiftiomatic", targets: ["Swiftiomatic"]),
    .plugin(name: "FormatPlugin", targets: ["Format Source Code"]),
    .plugin(name: "LintPlugin", targets: ["Lint Source Code"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
    .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.7.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", branch: "main"),
  ],
  targets: [
    .target(
      name: "Swiftiomatic",
      dependencies: [
        .product(name: "Markdown", package: "swift-markdown"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftiomaticTestSupport",
      dependencies: [
        "Swiftiomatic",
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
      ],
      path: "Tests/SwiftiomaticTestSupport"
    ),
    .target(
      name: "_GenerateSwiftiomatic",
      dependencies: ["Swiftiomatic"]
    ),
    .plugin(
      name: "Format Source Code",
      capability: .command(
        intent: .sourceCodeFormatting(),
        permissions: [
          .writeToPackageDirectory(reason: "This command formats the Swift source files")
        ]
      ),
      dependencies: [.target(name: "sm")],
      path: "Plugins/FormatPlugin"
    ),
    .plugin(
      name: "Lint Source Code",
      capability: .command(
        intent: .custom(
          verb: "lint-source-code",
          description: "Lint source code for a specified target."
        )
      ),
      dependencies: [.target(name: "sm")],
      path: "Plugins/LintPlugin"
    ),
    .executableTarget(
      name: "generate-swiftiomatic",
      dependencies: ["_GenerateSwiftiomatic"]
    ),
    .executableTarget(
      name: "sm",
      dependencies: [
        "Swiftiomatic",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftiomaticPerformanceTests",
      dependencies: [
        "Swiftiomatic",
        "SwiftiomaticTestSupport",
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftiomaticTests",
      dependencies: [
        "Swiftiomatic",
        "SwiftiomaticTestSupport",
        "_GenerateSwiftiomatic",
        .product(name: "Markdown", package: "swift-markdown"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
