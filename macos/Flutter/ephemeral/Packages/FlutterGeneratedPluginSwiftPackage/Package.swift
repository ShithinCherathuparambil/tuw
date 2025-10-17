// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "video_player_avfoundation", path: "../.packages/video_player_avfoundation"),
        .package(name: "device_info_plus", path: "../.packages/device_info_plus"),
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation"),
        .package(name: "record_macos", path: "../.packages/record_macos"),
        .package(name: "path_provider_foundation", path: "../.packages/path_provider_foundation"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging"),
        .package(name: "firebase_core", path: "../.packages/firebase_core"),
        .package(name: "file_picker", path: "../.packages/file_picker"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin"),
        .package(name: "audioplayers_darwin", path: "../.packages/audioplayers_darwin")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "device-info-plus", package: "device_info_plus"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "record-macos", package: "record_macos"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "file-picker", package: "file_picker"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "audioplayers-darwin", package: "audioplayers_darwin")
            ]
        )
    ]
)
