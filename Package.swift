// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sass-Swift",
    products: [
        .library(name: "Sass", targets: ["Sass"]),
        .library(name: "libsass", targets: ["libsass"])
    ],
    targets: [
        .target(name: "Sass", dependencies: ["libsass"], path: "Sources/Swift"),
        .testTarget(name: "Sass-Swift-Tests", dependencies: ["Sass"], path: "Tests/Swift"),
        .systemLibrary(name: "libsass", path: "Sources/C", pkgConfig: "libsass", providers: [.brew(["libsass"]), .apt(["libsass"])])
    ]
)
