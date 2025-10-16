// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MetalSCene2D-3D",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MetalSCene2D_3D", targets: ["MetalSCene2D_3D"]),
    ],
    dependencies: [
        // Si luego quieres FormuMath:
        // .package(url: "https://github.com/TU_ORG/FormuMath.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "MetalSCene2D_3D",
            dependencies: [
                // .product(name: "FormuMath", package: "FormuMath")
            ]
        ),
        .testTarget(
            name: "MetalSCene2D_3DTests",
            dependencies: ["MetalSCene2D_3D"]
        ),
    ]
)

