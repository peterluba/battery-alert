// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BatteryAlert",
    platforms: [
        .macOS("26.0")
    ],
    targets: [
        .executableTarget(
            name: "BatteryAlert",
            path: "Sources/BatteryAlert"
        )
    ]
)
