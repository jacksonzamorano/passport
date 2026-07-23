// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
import CompilerPluginSupport


let package = Package(
    name: "Passport",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Passport", targets: ["Passport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Passport", path: "Sources/Passport", swiftSettings: [.enableUpcomingFeature("ApproachableConcurrency")]),
        .executableTarget(name: "PassportDemo", dependencies: ["Passport"], path: "Sources/PassportDemo"),
    ],
)
