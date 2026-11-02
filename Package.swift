// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReaderMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ReaderMac",
            targets: ["ReaderMac"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ReaderMac",
            dependencies: [],
            path: "Sources/ReaderMac"
        )
    ]
)
