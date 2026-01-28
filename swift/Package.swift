// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MaskPII",
    platforms: [
        .macOS(.v12),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "MaskPII", targets: ["MaskPII"])
    ],
    targets: [
        .target(
            name: "MaskPII",
            path: "Sources"
        ),
        .testTarget(
            name: "MaskPIITests",
            dependencies: ["MaskPII"],
            path: "Tests"
        )
    ]
)
