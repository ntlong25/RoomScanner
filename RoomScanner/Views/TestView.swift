//
//  TestView.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 27/01/2024.
//

import SwiftUI
import RoomPlan

struct TestView: View {
    var body: some View {
        NavigationView {
            VStack {
                // Your existingScanView can be represented by a SwiftUI view here
                Text("Your Existing Scan View")
                    .padding()
                
                NavigationLink(destination: ScanRoomView()) {
                    Text("Start Scan")
                        .padding()
                }
            }
            .navigationBarTitle("Scanner App")
        }
    }
}


#Preview {
    TestView()
}
