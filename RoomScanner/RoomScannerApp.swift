//
//  RoomScannerApp.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 30/01/2024.
//

import SwiftUI

@main
struct RoomScannerApp: App {
  static let roomController = RoomCaptureController()
  var body: some Scene {
    WindowGroup {
      OnboardingView()
        .environment(RoomScannerApp.roomController)
    }
  }
}
