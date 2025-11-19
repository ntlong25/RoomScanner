//
//  ScanGalleryView.swift
//  RoomScanner
//
//  Created by Claude on 19/11/2025.
//

import SwiftUI
import SwiftData

struct ScanGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RoomScanRecord.scanDate, order: .reverse) private var scans: [RoomScanRecord]

    @State private var selectedScans: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var showingDeleteAlert = false
    @State private var showingComparison = false
    @State private var searchText = ""

    var filteredScans: [RoomScanRecord] {
        if searchText.isEmpty {
            return scans
        }
        return scans.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if scans.isEmpty {
                    emptyStateView
                } else {
                    scanListView
                }
            }
            .navigationTitle("Scan History")
            .searchable(text: $searchText, prompt: "Search scans")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !scans.isEmpty {
                        Button(isSelectionMode ? "Done" : "Select") {
                            isSelectionMode.toggle()
                            if !isSelectionMode {
                                selectedScans.removeAll()
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode && selectedScans.count >= 2 {
                        Button("Compare") {
                            showingComparison = true
                        }
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    if isSelectionMode && !selectedScans.isEmpty {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete \(selectedScans.count) items", systemImage: "trash")
                        }
                    }
                }
            }
            .alert("Delete Scans", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedScans()
                }
            } message: {
                Text("Are you sure you want to delete \(selectedScans.count) scan(s)? This cannot be undone.")
            }
            .sheet(isPresented: $showingComparison) {
                let selectedRecords = scans.filter { selectedScans.contains($0.id) }
                ScanComparisonView(scans: Array(selectedRecords.prefix(2)))
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Scans Yet")
                .font(.title2.bold())

            Text("Your scanned rooms will appear here")
                .foregroundColor(.secondary)
        }
    }

    private var scanListView: some View {
        List {
            // Storage info section
            Section {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.blue)
                    Text("Storage Used")
                    Spacer()
                    Text(ScanHistoryManager.formatStorageSize(
                        ScanHistoryManager.shared.getTotalStorageUsed()
                    ))
                    .foregroundColor(.secondary)
                }
            }

            // Scans section
            Section("Recent Scans (\(filteredScans.count))") {
                ForEach(filteredScans) { scan in
                    ScanRowView(
                        scan: scan,
                        isSelected: selectedScans.contains(scan.id),
                        isSelectionMode: isSelectionMode
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelectionMode {
                            toggleSelection(for: scan.id)
                        }
                    }
                }
                .onDelete(perform: deleteScan)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func toggleSelection(for id: UUID) {
        if selectedScans.contains(id) {
            selectedScans.remove(id)
        } else {
            selectedScans.insert(id)
        }
    }

    private func deleteScan(at offsets: IndexSet) {
        for index in offsets {
            let scan = filteredScans[index]
            ScanHistoryManager.shared.deleteScanFiles(scanId: scan.id)
            modelContext.delete(scan)
        }
    }

    private func deleteSelectedScans() {
        for scanId in selectedScans {
            if let scan = scans.first(where: { $0.id == scanId }) {
                ScanHistoryManager.shared.deleteScanFiles(scanId: scan.id)
                modelContext.delete(scan)
            }
        }
        selectedScans.removeAll()
        isSelectionMode = false
    }
}

// MARK: - Scan Row View
struct ScanRowView: View {
    let scan: RoomScanRecord
    let isSelected: Bool
    let isSelectionMode: Bool

    var body: some View {
        HStack(spacing: 12) {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }

            // Thumbnail
            if let thumbnailData = scan.thumbnailData,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "cube")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(scan.name)
                    .font(.headline)

                Text(scan.scanDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Label("\(scan.wallCount)", systemImage: "square.split.2x2")
                    Label(String(format: "%.1fm²", scan.totalArea), systemImage: "square.dashed")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            if !isSelectionMode {
                // Quality indicator
                QualityBadge(score: scan.qualityScore)

                NavigationLink(destination: ScanDetailView(scan: scan)) {
                    EmptyView()
                }
                .frame(width: 0)
                .opacity(0)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quality Badge
struct QualityBadge: View {
    let score: Int

    var color: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    var body: some View {
        Text("\(score)")
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(12)
    }
}

#Preview {
    ScanGalleryView()
        .modelContainer(for: RoomScanRecord.self, inMemory: true)
}
