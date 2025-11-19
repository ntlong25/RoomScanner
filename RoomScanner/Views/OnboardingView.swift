//
//  OnboardingView.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 27/01/2024.
//  Updated with new features on 19/11/2025.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(RoomCaptureController.self) var roomController
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RoomScanRecord.scanDate, order: .reverse) private var recentScans: [RoomScanRecord]

    @State private var showingScanOptions = false
    @State private var showingGallery = false
    @State private var scanName = "Room Scan"
    @State private var navigateToScan = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Quick Actions
                    quickActionsSection

                    // Recent Scans
                    recentScansSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("RoomScanner")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ScanGalleryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingScanOptions) {
                scanOptionsSheet
            }
            .navigationDestination(isPresented: $navigateToScan) {
                ScanRoomView()
            }
        }
        .onAppear {
            roomController.modelContext = modelContext
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("RoomPlan")
                .font(.title.bold())

            Text("To scan your room, point your device at all the walls, windows, doors and furniture in your space until your scan is complete.")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Text("You can see a preview of your scan at the bottom of the screen so you can make sure your scan is correct.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            // Main scan button
            Button {
                showingScanOptions = true
            } label: {
                HStack {
                    Image(systemName: "viewfinder")
                    Text("Start Scanning")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Secondary actions
            HStack(spacing: 12) {
                NavigationLink(destination: ScanGalleryView()) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.title2)
                        Text("Gallery")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                if let lastScan = recentScans.first,
                   let usdzPath = lastScan.usdzFileURL {
                    NavigationLink(destination: ARFurniturePlacementView(
                        roomModelURL: URL(fileURLWithPath: usdzPath)
                    )) {
                        VStack(spacing: 8) {
                            Image(systemName: "arkit")
                                .font(.title2)
                            Text("AR View")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "arkit")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("AR View")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Recent Scans Section
    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Scans")
                    .font(.headline)
                Spacer()
                if !recentScans.isEmpty {
                    NavigationLink("See All") {
                        ScanGalleryView()
                    }
                    .font(.subheadline)
                }
            }

            if recentScans.isEmpty {
                emptyRecentScansView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentScans.prefix(3)) { scan in
                        NavigationLink(destination: ScanDetailView(scan: scan)) {
                            RecentScanCard(scan: scan)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyRecentScansView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cube.transparent")
                .font(.largeTitle)
                .foregroundColor(.gray)

            Text("No scans yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Your scanned rooms will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Scan Options Sheet
    private var scanOptionsSheet: some View {
        NavigationStack {
            Form {
                Section("Scan Name") {
                    TextField("Enter scan name", text: $scanName)
                }

                Section("Scan Mode") {
                    Button {
                        roomController.scanName = scanName
                        roomController.isMultiRoomMode = false
                        showingScanOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            navigateToScan = true
                        }
                    } label: {
                        Label("Single Room", systemImage: "square")
                    }

                    Button {
                        roomController.scanName = scanName
                        roomController.isMultiRoomMode = true
                        showingScanOptions = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            navigateToScan = true
                        }
                    } label: {
                        Label("Multiple Rooms", systemImage: "square.grid.2x2")
                    }
                }

                Section("Export Options") {
                    Toggle("USDZ 3D Model", isOn: Binding(
                        get: { roomController.exportUSDZ },
                        set: { roomController.exportUSDZ = $0 }
                    ))

                    Toggle("JSON Data", isOn: Binding(
                        get: { roomController.exportJSON },
                        set: { roomController.exportJSON = $0 }
                    ))

                    Toggle("PDF Report", isOn: Binding(
                        get: { roomController.exportPDF },
                        set: { roomController.exportPDF = $0 }
                    ))
                }
            }
            .navigationTitle("Scan Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingScanOptions = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Recent Scan Card
struct RecentScanCard: View {
    let scan: RoomScanRecord

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnailData = scan.thumbnailData,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "cube")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(scan.name)
                    .font(.subheadline.bold())

                HStack(spacing: 8) {
                    Label(String(format: "%.1fm²", scan.totalArea), systemImage: "square.dashed")
                    Label("\(scan.qualityScore)%", systemImage: "star")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView()
        .environment(RoomCaptureController())
        .modelContainer(for: RoomScanRecord.self, inMemory: true)
}
