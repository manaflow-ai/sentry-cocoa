// swift-tools-version:6.1

import PackageDescription

// Manaflow's source-built package exposes one audited Sentry module for cmux.
// Binary products, optional UI-framework adapters, and unrelated platforms are absent.
let package = Package(
    name: "Sentry",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(name: "Sentry", targets: ["Sentry", "SentryCppHelper"]),
    ],
    targets: [
        .target(
            name: "SentryHeaders",
            path: "Sources/Sentry",
            sources: ["SentryDummyPublicEmptyClass.m"],
            publicHeadersPath: "Public"
        ),
        .target(
            name: "_SentryPrivate",
            dependencies: ["SentryHeaders"],
            path: "Sources/Sentry",
            sources: ["SentryDummyPrivateEmptyClass.m"],
            publicHeadersPath: "include"
        ),
        .target(
            name: "SentrySwift",
            dependencies: ["_SentryPrivate", "SentryHeaders"],
            path: "Sources/Swift",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .target(
            name: "SentryObjCInternal",
            dependencies: ["SentrySwift"],
            path: "Sources",
            exclude: [
                "Configuration",
                "Resources",
                "Sentry/SentryDummyPrivateEmptyClass.m",
                "Sentry/SentryDummyPublicEmptyClass.m",
                "SentryCppHelper",
                "SentryDistribution",
                "SentryDistributionTests",
                "SentryFacade",
                "Swift",
            ],
            cSettings: [
                .headerSearchPath("Sentry"),
                .headerSearchPath("SentryCrash/Installations"),
                .headerSearchPath("SentryCrash/Recording"),
                .headerSearchPath("SentryCrash/Recording/Monitors"),
                .headerSearchPath("SentryCrash/Recording/Tools"),
                .headerSearchPath("SentryCrash/Reporting/Filters"),
                .headerSearchPath("SentryCrash/Reporting/Filters/Tools"),
            ]
        ),
        .target(
            name: "Sentry",
            dependencies: ["SentrySwift", "SentryObjCInternal"],
            path: "Sources/SentryFacade"
        ),
        .target(
            name: "SentryCppHelper",
            path: "Sources/SentryCppHelper",
            linkerSettings: [
                .linkedLibrary("c++"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6],
    cxxLanguageStandard: .cxx14
)
