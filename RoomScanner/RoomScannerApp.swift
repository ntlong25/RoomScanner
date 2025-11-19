//
//  RoomScannerApp.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 30/01/2024.
//  Updated with new features on 19/11/2025.
//

import SwiftUI
import SwiftData

@main
struct RoomScannerApp: App {
    static let roomController = RoomCaptureController()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RoomScanRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environment(RoomScannerApp.roomController)
        }
        .modelContainer(sharedModelContainer)
    }
}
