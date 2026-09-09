// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CopyWheel",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Fork mit Fix: Ressourcen-Bundle-Auflösung crasht nicht, wenn die
        // App per "swift build" gebaut und manuell gebundelt wird.
        // (Upstream: sindresorhus/KeyboardShortcuts 2.4.0)
        .package(
            url: "https://github.com/weselski/KeyboardShortcuts",
            revision: "ae40bf368f5c4dee7b03d02c024e12e44a945e34"
        ),
    ],
    targets: [
        .executableTarget(
            name: "CopyWheel",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ]
        ),
    ]
)
