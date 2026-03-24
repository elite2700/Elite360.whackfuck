// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Elite360Whackfuck",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Elite360Whackfuck",
            targets: ["Elite360Whackfuck"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.0.0"),
        .package(url: "https://github.com/google/generative-ai-swift.git", from: "0.5.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "Elite360Whackfuck",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "RevenueCat", package: "purchases-ios-spm"),
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            path: "Elite360Whackfuck"
        )
    ]
)
