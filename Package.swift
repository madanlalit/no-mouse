// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoMouse",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NoMouse", targets: ["NoMouse"])
    ],
    targets: [
        .executableTarget(
            name: "NoMouse",
            path: "NoMouse"
        )
    ]
)
