//
//  OnboardingView.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 27/01/2024.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("RoomPlan")
                    .font(.title.bold())
                    .padding(.bottom, 20)
                
                Text("To scan your room, point your device at all the walls, windows, doors and furniture in your space until your scan is complete.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                
                Text("You can see a preview of your scan at the bottom of the screen so you can make sure your scan is correct.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                
                Spacer()
                Text("Recent model")
                // Model list show here after scanning done
                Spacer()
                
                NavigationLink(destination: ScanRoomView()) {
                    Text("Start Scanning")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .font(.title3)
            }
            .padding()
        }
    }
}

#Preview {
    OnboardingView()
}
