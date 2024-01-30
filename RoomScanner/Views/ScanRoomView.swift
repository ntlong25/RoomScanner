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
    @Environment(Model.self) var model
    
    @State var showShareSheet = false
    var body : some View {
        
        @Bindable var bindableModel = model
        
        ZStack(alignment: .bottom) {
            RoomCaptureRep()
                .edgesIgnoringSafeArea(.all)
                .navigationBarItems(leading: Button("Cancel") {
                    model.stopSession()
                    presentationMode.wrappedValue.dismiss()
                })
                .navigationBarItems(trailing: Button("Done") {
                    model.stopSession()
                    model.showExportButton = true
                }
                .opacity(model.showExportButton ? 0 : 1))
                .onAppear() {
                    model.showExportButton = false
                    model.startSession()
                }
            
            Button {
                model.export()
                showShareSheet = true
            } label: {
                Text("Export")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .opacity(model.showExportButton ? 1 : 0)
            .padding()
            .sheet(isPresented: $bindableModel.showShareSheet, content: {
                ActivityView(items: [model.exportUrl!])
                    .onDisappear() {
                        showShareSheet = false
                        presentationMode.wrappedValue.dismiss()
                    }
            })
        }
    }
}

struct RoomCaptureRep: UIViewRepresentable {
    @Environment(Model.self) var model
    
    func makeUIView(context: Context) -> RoomCaptureView {
        return model.roomCaptureView
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
