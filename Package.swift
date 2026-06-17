// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Coffein",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Coffein",
            path: "Sources/Coffein"
        )
    ],
    swiftLanguageModes: [.v5]
)
