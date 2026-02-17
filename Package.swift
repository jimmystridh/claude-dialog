// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "claude-dialog",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "claude-dialog",
            path: "Sources/claude-dialog"
        ),
    ]
)
