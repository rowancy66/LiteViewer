// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiteViewer",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "LiteViewerCore", targets: ["LiteViewerCore"]),
        .executable(name: "LiteViewer", targets: ["LiteViewer"]),
        .executable(name: "LiteViewerCoreChecks", targets: ["LiteViewerCoreChecks"])
    ],
    targets: [
        .target(
            name: "LiteViewerCore",
            path: "Sources/MacImageViewerCore"
        ),
        .executableTarget(
            name: "LiteViewer",
            dependencies: ["LiteViewerCore"],
            path: "Sources/MacImageViewer"
        ),
        .executableTarget(
            name: "LiteViewerCoreChecks",
            dependencies: ["LiteViewerCore"],
            path: "Sources/MacImageViewerCoreChecks"
        )
    ]
)
