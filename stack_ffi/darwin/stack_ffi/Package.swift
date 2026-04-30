// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "stack_ffi",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15"),
    ],
    products: [
        .library(name: "stack-ffi", targets: ["stack_ffi"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "stack_ffi",
            dependencies: [
                // Shared code
                .target(name: "stack_ffi_darwin"),
                .target(name: "stack_ffi_darwin_bindings"),

                // macOS specific code
                .target(name: "stack_ffi_macos_bindings", condition: .when(platforms: [.macOS])),

                // iOS specific code
                .target(name: "stack_ffi_ios_bindings", condition: .when(platforms: [.iOS]))
            ]
        ),
        .target(
            name: "stack_ffi_darwin",
            path: "Sources/stack_ffi_darwin"
        ),
        .target(
            name: "stack_ffi_darwin_bindings",
            path: "Sources/stack_ffi_darwin_bindings",
            publicHeadersPath: "."
        ),
        .target(
            name: "stack_ffi_macos",
            path: "Sources/stack_ffi_macos",
            packageAccess: true
        ),
        .target(
            name: "stack_ffi_macos_bindings",
            path: "Sources/stack_ffi_macos_bindings",
            publicHeadersPath: "."
        ),
        .target(
            name: "stack_ffi_ios",
            path: "Sources/stack_ffi_ios",
            packageAccess: true
        ),
        .target(
            name: "stack_ffi_ios_bindings",
            path: "Sources/stack_ffi_ios_bindings",
            publicHeadersPath: "."
        )
    ]
)
