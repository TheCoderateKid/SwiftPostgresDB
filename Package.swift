// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPostgresDB",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "SwiftPostgresDB",
            targets: ["SwiftPostgresDB"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.25.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.3.1"),
    ],
    targets: [
        .target(
            name: "SwiftPostgresDB",
            dependencies: [
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .testTarget(
            name: "SwiftPostgresDBTests",
            dependencies: ["SwiftPostgresDB"]
        ),
    ]
)
