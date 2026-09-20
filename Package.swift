// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexHairBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexHairBar", targets: ["CodexHairBar"])
    ],
    targets: [
        .executableTarget(
            name: "CodexHairBar",
            path: "Sources/CodexHairBar"
        ),
        .testTarget(
            name: "CodexHairBarTests",
            dependencies: ["CodexHairBar"],
            path: "Tests/CodexHairBarTests"
        )
    ]
)
