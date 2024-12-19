//
//  Package.swift
//  CiCdTesting
//
//  Created by New on 18.12.24..
//

// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.9.0"),
    ],
    targets: [
        .target(
            name: "CiCdTesting",
            dependencies: []),
        .testTarget(
            name: "CiCdTestingUITests",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)

