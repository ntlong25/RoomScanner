//
//  ScanComparisonView.swift
//  RoomScanner
//
//  Created by Claude on 19/11/2025.
//

import SwiftUI

struct ScanComparisonView: View {
    @Environment(\.dismiss) private var dismiss

    let scans: [RoomScanRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Comparison cards
                    comparisonSection
                }
                .padding()
            }
            .navigationTitle("Compare Scans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 12) {
            ForEach(scans) { scan in
                VStack(spacing: 8) {
                    if let thumbnailData = scan.thumbnailData,
                       let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .cornerRadius(8)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 100)
                            .overlay(
                                Image(systemName: "cube")
                                    .foregroundColor(.gray)
                            )
                    }

                    Text(scan.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text(scan.scanDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Comparison Section
    private var comparisonSection: some View {
        VStack(spacing: 16) {
            // Quality Score
            ComparisonRow(
                title: "Quality Score",
                icon: "star.fill",
                values: scans.map { "\($0.qualityScore)/100" },
                highlights: highlightBetter(values: scans.map { Double($0.qualityScore) })
            )

            // Floor Area
            ComparisonRow(
                title: "Floor Area",
                icon: "square.dashed",
                values: scans.map { String(format: "%.2f m²", $0.totalArea) },
                highlights: highlightBigger(values: scans.map { $0.totalArea })
            )

            // Volume
            ComparisonRow(
                title: "Volume",
                icon: "cube",
                values: scans.map { String(format: "%.2f m³", $0.totalVolume) },
                highlights: highlightBigger(values: scans.map { $0.totalVolume })
            )

            // Width
            ComparisonRow(
                title: "Width",
                icon: "arrow.left.and.right",
                values: scans.map { String(format: "%.2f m", $0.roomWidth) },
                highlights: highlightBigger(values: scans.map { $0.roomWidth })
            )

            // Length
            ComparisonRow(
                title: "Length",
                icon: "arrow.up.and.down",
                values: scans.map { String(format: "%.2f m", $0.roomLength) },
                highlights: highlightBigger(values: scans.map { $0.roomLength })
            )

            // Height
            ComparisonRow(
                title: "Height",
                icon: "arrow.up.to.line",
                values: scans.map { String(format: "%.2f m", $0.roomHeight) },
                highlights: highlightBigger(values: scans.map { $0.roomHeight })
            )

            // Walls
            ComparisonRow(
                title: "Walls",
                icon: "square.split.2x2",
                values: scans.map { "\($0.wallCount)" },
                highlights: [false, false]
            )

            // Doors
            ComparisonRow(
                title: "Doors",
                icon: "door.left.hand.open",
                values: scans.map { "\($0.doorCount)" },
                highlights: [false, false]
            )

            // Windows
            ComparisonRow(
                title: "Windows",
                icon: "window.vertical.open",
                values: scans.map { "\($0.windowCount)" },
                highlights: [false, false]
            )

            // Objects
            ComparisonRow(
                title: "Objects",
                icon: "chair",
                values: scans.map { "\($0.objectCount)" },
                highlights: [false, false]
            )
        }
    }

    // MARK: - Helper Functions
    private func highlightBetter(values: [Double]) -> [Bool] {
        guard values.count == 2 else { return [false, false] }
        if values[0] > values[1] {
            return [true, false]
        } else if values[1] > values[0] {
            return [false, true]
        }
        return [false, false]
    }

    private func highlightBigger(values: [Double]) -> [Bool] {
        guard values.count == 2 else { return [false, false] }
        if values[0] > values[1] {
            return [true, false]
        } else if values[1] > values[0] {
            return [false, true]
        }
        return [false, false]
    }
}

// MARK: - Comparison Row
struct ComparisonRow: View {
    let title: String
    let icon: String
    let values: [String]
    let highlights: [Bool]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    Text(value)
                        .font(.body.bold())
                        .foregroundColor(highlights[index] ? .green : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            highlights[index] ?
                            Color.green.opacity(0.1) :
                            Color(.systemGray5)
                        )
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ScanComparisonView(scans: [
        RoomScanRecord(
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
        ),
        RoomScanRecord(
            name: "Bedroom",
            totalArea: 18.0,
            totalVolume: 45.0,
            wallCount: 4,
            doorCount: 1,
            windowCount: 2,
            objectCount: 5,
            roomWidth: 4.0,
            roomLength: 4.5,
            roomHeight: 2.5,
            qualityScore: 78
        )
    ])
}
