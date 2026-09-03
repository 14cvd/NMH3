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
            sources: [
                // Thin ObjC wrappers over the real H3 C API
                "NMH3Grid.m",
                "NMH3Index.m",
                "NMH3Region.m",
                "NMH3Compact.m",
                // Vendored Uber H3 C core (v4.1.0, Apache-2.0)
                "h3/lib/algos.c",
                "h3/lib/baseCells.c",
                "h3/lib/bbox.c",
                "h3/lib/coordijk.c",
                "h3/lib/directedEdge.c",
                "h3/lib/faceijk.c",
                "h3/lib/h3Assert.c",
                "h3/lib/h3Index.c",
                "h3/lib/iterators.c",
                "h3/lib/latLng.c",
                "h3/lib/linkedGeo.c",
                "h3/lib/localij.c",
                "h3/lib/mathExtensions.c",
                "h3/lib/polygon.c",
                "h3/lib/vec2d.c",
                "h3/lib/vec3d.c",
                "h3/lib/vertex.c",
                "h3/lib/vertexGraph.c",
            ],
            publicHeadersPath: "include",
            cSettings: [
                // Expose both our ObjC include dir and the H3 internal include dir
                .headerSearchPath("h3/include"),
            ]
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
