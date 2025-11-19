//
//  MeasurementOverlayView.swift
//  RoomScanner
//
//  Created by Claude on 19/11/2025.
//

import SwiftUI

struct MeasurementOverlayView: View {
    let measurements: RoomMeasurements

    @State private var isExpanded = false

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                // Toggle button
                Button {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        Text("Live Measurements")
                            .font(.subheadline.bold())
                        Spacer()
                        QualityIndicator(score: measurements.qualityScore)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground).opacity(0.95))
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()
                    expandedContent
                }
            }
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
    }

    private var expandedContent: some View {
        VStack(spacing: 12) {
            // Main measurements
            HStack(spacing: 16) {
                MeasurementPill(
                    icon: "square.dashed",
                    value: String(format: "%.1f", measurements.totalFloorArea),
                    unit: "m²",
                    label: "Area"
                )

                MeasurementPill(
                    icon: "cube",
                    value: String(format: "%.1f", measurements.totalVolume),
                    unit: "m³",
                    label: "Volume"
                )
            }

            // Dimensions
            HStack(spacing: 8) {
                DimensionChip(label: "W", value: measurements.roomWidth)
                DimensionChip(label: "L", value: measurements.roomLength)
                DimensionChip(label: "H", value: measurements.roomHeight)
            }

            // Element counts
            HStack(spacing: 16) {
                ElementCount(icon: "square.split.2x2", count: measurements.wallCount)
                ElementCount(icon: "door.left.hand.open", count: measurements.doorCount)
                ElementCount(icon: "window.vertical.open", count: measurements.windowCount)
                ElementCount(icon: "chair", count: measurements.objectCount)
            }
        }
        .padding()
    }
}

// MARK: - Quality Indicator
struct QualityIndicator: View {
    let score: Int

    var color: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(score)%")
                .font(.caption.bold())
                .foregroundColor(color)
        }
    }
}

// MARK: - Measurement Pill
struct MeasurementPill: View {
    let icon: String
    let value: String
    let unit: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Text(value)
                        .font(.headline.bold())
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Dimension Chip
struct DimensionChip: View {
    let label: String
    let value: Double

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.secondary)
            Text(String(format: "%.1fm", value))
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(4)
    }
}

// MARK: - Element Count
struct ElementCount: View {
    let icon: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            Text("\(count)")
                .font(.caption.bold())
        }
    }
}

// MARK: - Scanning Progress View
struct ScanningProgressView: View {
    let progress: Double
    let statusMessage: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "viewfinder")
                    .foregroundColor(.blue)
                Text("Scanning...")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }

            ProgressView(value: progress)
                .tint(.blue)

            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)

        MeasurementOverlayView(
            measurements: RoomMeasurements(
                totalFloorArea: 25.5,
                totalWallArea: 45.0,
                totalVolume: 63.75,
                roomWidth: 5.1,
                roomLength: 5.0,
                roomHeight: 2.5,
                wallCount: 4,
                doorCount: 2,
                windowCount: 3,
                openingCount: 1,
                objectCount: 8,
                qualityScore: 85
            )
        )
    }
}
