// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NMH3",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "NMH3", targets: ["NMH3"]),
    ],
    targets: [
        .target(
            name: "NMCH3",
            path: "Sources/NMCH3",
            publicHeadersPath: "include"
        ),
        .target(
            name: "NMH3",
            dependencies: ["NMCH3"],
            path: "Sources/NMH3"
        ),
        .testTarget(
            name: "NMH3Tests",
            dependencies: ["NMH3"],
            path: "Tests/NMH3Tests"
        )
    ]
)
