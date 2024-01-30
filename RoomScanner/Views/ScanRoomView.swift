//
//  RoomCaptureView.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 27/01/2024.
//

import SwiftUI
import UIKit
import RoomPlan

struct ScanRoomView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(RoomCaptureController.self) var roomController
    
    var body : some View {
        
        @Bindable var bindableController = roomController
        
        ZStack(alignment: .bottom) {
            RoomCaptureRep()
                .edgesIgnoringSafeArea(.all)
                .navigationBarItems(leading: Button("Cancel") {
                    roomController.stopSession()
                    presentationMode.wrappedValue.dismiss()
                })
                .navigationBarItems(trailing: Button("Done") {
                    roomController.stopSession()
                    roomController.showExportButton = true
                }
                .opacity(roomController.showExportButton ? 0 : 1))
                .onAppear() {
                    roomController.showExportButton = false
                    roomController.startSession()
                }
            
            Button {
                roomController.export()
            } label: {
                Text("Export")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .opacity(roomController.showExportButton ? 1 : 0)
            .padding()
            .sheet(isPresented: $bindableController.showShareSheet, content: {
                ActivityView(items: [roomController.exportUrl!])
                    .onDisappear() {
                        presentationMode.wrappedValue.dismiss()
                    }
            })
        }
    }
}

struct RoomCaptureRep: UIViewRepresentable {
    @Environment(RoomCaptureController.self) var roomController
    
    func makeUIView(context: Context) -> RoomCaptureView {
        return roomController.roomCaptureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
    }
    
}

struct ActivityView: UIViewControllerRepresentable {
  var items: [Any]
  var activities: [UIActivity]? = nil
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: activities)
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}


#Preview {
    ScanRoomView()
}
