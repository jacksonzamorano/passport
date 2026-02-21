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
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "600.0.1"
        ),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Passport", dependencies: ["PassportMacros"], path: "Sources/Passport"),
        .macro(name: "PassportMacros", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
        ], path: "Sources/PassportMacros"),
        .executableTarget(name: "PassportDemo", dependencies: ["Passport"], path: "Sources/PassportDemo"),
    ],
)
