// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Rainier",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "RainierCore",
            path: "Sources/RainierCore"
        ),
        .executableTarget(
            name: "Rainier",
            dependencies: ["RainierCore"],
            path: "Sources/Rainier"
        ),
        .executableTarget(
            name: "RainierTests",
            dependencies: ["RainierCore"],
            path: "Sources/RainierTests"
        ),
    ]
)
