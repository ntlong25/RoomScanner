//
//  ScanDetailView.swift
//  RoomScanner
//
//  Created by Claude on 19/11/2025.
//

import SwiftUI
import QuickLook

struct ScanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let scan: RoomScanRecord

    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedNotes: String = ""
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingQuickLook = false
    @State private var previewURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with thumbnail
                headerSection

                // Quality Score
                qualitySection

                // Measurements
                measurementsSection

                // Room Elements
                elementsSection

                // Actions
                actionsSection

                // Notes
                notesSection
            }
            .padding()
        }
        .navigationTitle(scan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        editedName = scan.name
                        editedNotes = scan.notes
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            editSheet
        }
        .sheet(isPresented: $showingShareSheet) {
            let urls = ScanHistoryManager.shared.getFileURLs(for: scan)
            if !urls.isEmpty {
                ActivityView(items: urls)
            }
        }
        .quickLookPreview($previewURL)
        .alert("Delete Scan", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteScan()
            }
        } message: {
            Text("Are you sure you want to delete this scan? This cannot be undone.")
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            if let thumbnailData = scan.thumbnailData,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "cube.transparent")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }

            Text(scan.scanDate, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Quality Section
    private var qualitySection: some View {
        let feedback = QualityValidator.getQualityFeedback(score: scan.qualityScore)

        return VStack(spacing: 8) {
            HStack {
                Text("Quality Score")
                    .font(.headline)
                Spacer()
            }

            HStack {
                ProgressView(value: Double(scan.qualityScore), total: 100)
                    .tint(feedback.color)

                Text("\(scan.qualityScore)/100")
                    .font(.title3.bold())
                    .foregroundColor(feedback.color)
            }

            Text(feedback.message)
                .font(.caption)
                .foregroundColor(feedback.color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Measurements Section
    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dimensions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MeasurementCard(
                    title: "Floor Area",
                    value: String(format: "%.2f", scan.totalArea),
                    unit: "m²",
                    icon: "square.dashed"
                )

                MeasurementCard(
                    title: "Volume",
                    value: String(format: "%.2f", scan.totalVolume),
                    unit: "m³",
                    icon: "cube"
                )

                MeasurementCard(
                    title: "Width",
                    value: String(format: "%.2f", scan.roomWidth),
                    unit: "m",
                    icon: "arrow.left.and.right"
                )

                MeasurementCard(
                    title: "Length",
                    value: String(format: "%.2f", scan.roomLength),
                    unit: "m",
                    icon: "arrow.up.and.down"
                )

                MeasurementCard(
                    title: "Height",
                    value: String(format: "%.2f", scan.roomHeight),
                    unit: "m",
                    icon: "arrow.up.to.line"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Elements Section
    private var elementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Room Elements")
                .font(.headline)

            HStack(spacing: 16) {
                ElementBadge(icon: "square.split.2x2", count: scan.wallCount, label: "Walls")
                ElementBadge(icon: "door.left.hand.open", count: scan.doorCount, label: "Doors")
                ElementBadge(icon: "window.vertical.open", count: scan.windowCount, label: "Windows")
                ElementBadge(icon: "chair", count: scan.objectCount, label: "Objects")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Text("Export Files")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                if let usdzPath = scan.usdzFileURL {
                    ActionButton(title: "3D Model", icon: "cube.fill", color: .blue) {
                        previewURL = URL(fileURLWithPath: usdzPath)
                        showingQuickLook = true
                    }
                }

                if let jsonPath = scan.jsonFileURL {
                    ActionButton(title: "JSON", icon: "doc.text.fill", color: .orange) {
                        previewURL = URL(fileURLWithPath: jsonPath)
                    }
                }

                if let pdfPath = scan.pdfFileURL {
                    ActionButton(title: "PDF", icon: "doc.richtext.fill", color: .red) {
                        previewURL = URL(fileURLWithPath: pdfPath)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            if scan.notes.isEmpty {
                Text("No notes added")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                Text(scan.notes)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Edit Sheet
    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Scan Name", text: $editedName)
                }

                Section("Notes") {
                    TextEditor(text: $editedNotes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        scan.name = editedName
                        scan.notes = editedNotes
                        isEditing = false
                    }
                }
            }
        }
    }

    private func deleteScan() {
        ScanHistoryManager.shared.deleteScanFiles(scanId: scan.id)
        modelContext.delete(scan)
        dismiss()
    }
}

// MARK: - Supporting Views
struct MeasurementCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.title3.bold())

            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct ElementBadge: View {
    let icon: String
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text("\(count)")
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}

#Preview {
    NavigationStack {
        ScanDetailView(scan: RoomScanRecord(
            name: "Living Room",
            totalArea: 25.5,
            totalVolume: 63.75,
            wallCount: 4,
            doorCount: 2,
            windowCount: 3,
            objectCount: 8,
            roomWidth: 5.1,
            roomLength: 5.0,
            roomHeight: 2.5,
            qualityScore: 85
        ))
    }
}
