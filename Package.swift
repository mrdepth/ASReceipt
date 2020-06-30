// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ASReceipt",
//    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ASReceipt",
            targets: ["ASReceipt"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mrdepth/ASN1Decoder", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ASReceipt",
            dependencies: ["ASN1Decoder"]),
        .testTarget(
            name: "ASReceiptTests",
            dependencies: ["ASReceipt"],
            resources: [.copy("sandboxReceipt")]),
    ]
)
