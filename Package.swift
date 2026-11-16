// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DayCoach",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "DayCoach", targets: ["DayCoach"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        // Data and rules, with no user interface: testable on its own.
        .target(
            name: "DayCoachCore",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")]
        ),
        // The macOS app: menu bar item, main window, settings, notifications.
        .executableTarget(
            name: "DayCoach",
            dependencies: ["DayCoachCore"]
        ),
        .testTarget(
            name: "DayCoachCoreTests",
            dependencies: ["DayCoachCore"]
        ),
    ]
)
