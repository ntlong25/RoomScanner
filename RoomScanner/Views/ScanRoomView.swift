//
//  ScanRoomView.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 27/01/2024.
//  Updated with new features on 19/11/2025.
//

import SwiftUI
import UIKit
import RoomPlan

struct ScanRoomView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(RoomCaptureController.self) var roomController

    @State private var showMeasurements = true
    @State private var showingExportOptions = false

    var body: some View {

        @Bindable var bindableController = roomController

        ZStack {
            // Room capture view
            RoomCaptureRep()
                .edgesIgnoringSafeArea(.all)

            // Overlay content
            VStack {
                // Top bar with progress
                if !roomController.showExportButton {
                    topProgressBar
                }

                Spacer()

                // Real-time measurements overlay
                if showMeasurements && !roomController.showExportButton {
                    MeasurementOverlayView(measurements: roomController.currentMeasurements)
                        .transition(.move(edge: .bottom))
                }

                // Export button
                if roomController.showExportButton {
                    exportSection
                }
            }

            // Processing indicator
            if roomController.isProcessing {
                processingOverlay
            }

            // Toast messages
            if let toast = roomController.toastMessage {
                VStack {
                    ToastView(toast: toast)
                        .padding(.top, 100)
                    Spacer()
                }
                .transition(.move(edge: .top))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                        withAnimation {
                            roomController.toastMessage = nil
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    roomController.stopSession()
                    roomController.resetScan()
                    presentationMode.wrappedValue.dismiss()
                }
            }

            ToolbarItem(placement: .principal) {
                if roomController.isMultiRoomMode {
                    Text("Room \(roomController.currentRoomIndex + 1)")
                        .font(.headline)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    // Toggle measurements button
                    Button {
                        withAnimation {
                            showMeasurements.toggle()
                        }
                    } label: {
                        Image(systemName: showMeasurements ? "ruler.fill" : "ruler")
                    }
                    .opacity(roomController.showExportButton ? 0 : 1)

                    // Done/Next button
                    if roomController.isMultiRoomMode && !roomController.showExportButton {
                        Menu {
                            Button {
                                roomController.stopSession()
                                roomController.saveCurrentRoomAndContinue()
                            } label: {
                                Label("Save & Scan Next Room", systemImage: "arrow.right")
                            }

                            Button {
                                roomController.stopSession()
                                roomController.finishMultiRoomScan()
                            } label: {
                                Label("Finish Scanning", systemImage: "checkmark")
                            }
                        } label: {
                            Text("Next")
                        }
                    } else {
                        Button("Done") {
                            roomController.stopSession()
                            roomController.showExportButton = true
                        }
                        .opacity(roomController.showExportButton ? 0 : 1)
                    }
                }
            }
        }
        .onAppear() {
            roomController.showExportButton = false
            roomController.startSession()
        }
        .sheet(isPresented: $bindableController.showShareSheet) {
            if let url = roomController.exportUrl {
                ActivityView(items: [url])
                    .onDisappear() {
                        presentationMode.wrappedValue.dismiss()
                    }
            }
        }
        .errorAlert(alertItem: $bindableController.alertItem)
    }

    // MARK: - Top Progress Bar
    private var topProgressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "viewfinder")
                    .foregroundColor(.white)
                Text(roomController.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
            }

            ProgressView(value: roomController.scanProgress)
                .tint(.white)
        }
        .padding()
        .background(Color.black.opacity(0.6))
    }

    // MARK: - Export Section
    private var exportSection: some View {
        VStack(spacing: 16) {
            // Quality feedback
            let feedback = QualityValidator.getQualityFeedback(score: roomController.currentMeasurements.qualityScore)

            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(feedback.color)
                Text("Quality: \(roomController.currentMeasurements.qualityScore)/100")
                    .font(.headline)
                    .foregroundColor(feedback.color)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(20)

            // Quick stats
            HStack(spacing: 20) {
                StatBadge(
                    icon: "square.dashed",
                    value: String(format: "%.1f m²", roomController.currentMeasurements.totalFloorArea)
                )
                StatBadge(
                    icon: "cube",
                    value: String(format: "%.1f m³", roomController.currentMeasurements.totalVolume)
                )
                StatBadge(
                    icon: "square.split.2x2",
                    value: "\(roomController.currentMeasurements.wallCount) walls"
                )
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(12)

            // Export button
            Button {
                if roomController.isMultiRoomMode && roomController.scannedRooms.count > 0 {
                    roomController.exportAllRooms()
                } else {
                    roomController.export()
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(roomController.isMultiRoomMode ? "Export All Rooms" : "Export")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 30)
    }

    // MARK: - Processing Overlay
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Generating export files")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.caption.bold())
        }
    }
}

// MARK: - Room Capture Representable
struct RoomCaptureRep: UIViewRepresentable {
    @Environment(RoomCaptureController.self) var roomController

    func makeUIView(context: Context) -> RoomCaptureView {
        return roomController.roomCaptureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
    }
}

// MARK: - Activity View
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
    NavigationStack {
        ScanRoomView()
            .environment(RoomCaptureController())
    }
}
