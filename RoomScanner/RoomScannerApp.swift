//
//  RoomScannerApp.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 30/01/2024.
//

import SwiftUI

@main
struct RoomScannerApp: App {
  static let model = Model()
  var body: some Scene {
    WindowGroup {
      OnboardingView()
        .environment(RoomScannerApp.model)
    }
  }
}
