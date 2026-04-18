// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "swiftiomatic",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "sm", targets: ["Swiftiomatic"]),
        .library(name: "SwiftiomaticKit", targets: ["SwiftiomaticKit"]),
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
            name: "ConfigurationKit",
            exclude: ["README.md"]
        ),
        .target(
            name: "SwiftiomaticKit",
            dependencies: [
                "ConfigurationKit",
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            exclude: ["README.md"]
        ),
        .target(
            name: "SwiftiomaticTestSupport",
            dependencies: [
                "SwiftiomaticKit",
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            path: "Tests/SwiftiomaticTestSupport",
            exclude: ["README.md"]
        ),
        .target(
            name: "GeneratorKit",
            dependencies: [
                "SwiftiomaticKit",
                "ConfigurationKit",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            path: "Sources/GeneratorKit",
            exclude: ["README.md"]
        ),
        .plugin(
            name: "Format Source Code",
            capability: .command(
                intent: .sourceCodeFormatting(),
                permissions: [
                    .writeToPackageDirectory(reason: "This command formats the Swift source files")
                ]
            ),
            dependencies: [.target(name: "Swiftiomatic")],
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
            dependencies: [.target(name: "Swiftiomatic")],
            path: "Plugins/LintPlugin"
        ),
        .executableTarget(
            name: "Generator",
            dependencies: ["GeneratorKit"],
            exclude: ["README.md"]
        ),
        .executableTarget(
            name: "Swiftiomatic",
            dependencies: [
                "SwiftiomaticKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "SwiftiomaticPerformanceTests",
            dependencies: [
                "SwiftiomaticKit",
                "SwiftiomaticTestSupport",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "SwiftiomaticTests",
            dependencies: [
                "SwiftiomaticKit",
                "SwiftiomaticTestSupport",
                "GeneratorKit",
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            exclude: ["README.md"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
