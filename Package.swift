// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WithdrawalRateMath",
    products: [
        .library(name: "WithdrawalRateMath", targets: ["WithdrawalRateMath"])
    ],
    targets: [
        .target(name: "WithdrawalRateMath")
    ]
)
