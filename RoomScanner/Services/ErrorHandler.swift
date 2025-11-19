//
//  ErrorHandler.swift
//  RoomScanner
//
//  Created by Claude on 19/11/2025.
//

import Foundation
import SwiftUI

// MARK: - Custom Error Types
enum RoomScanError: LocalizedError {
    case sessionFailed(String)
    case exportFailed(String)
    case saveFailed(String)
    case invalidRoom
    case lowQualityScan(Int)
    case deviceNotSupported
    case cameraPermissionDenied
    case insufficientWalls
    case fileSystemError(String)
    case pdfGenerationFailed

    var errorDescription: String? {
        switch self {
        case .sessionFailed(let reason):
            return "Scan session failed: \(reason)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .saveFailed(let reason):
            return "Save failed: \(reason)"
        case .invalidRoom:
            return "Invalid room data captured"
        case .lowQualityScan(let score):
            return "Low quality scan detected (Score: \(score)/100)"
        case .deviceNotSupported:
            return "This device does not support room scanning"
        case .cameraPermissionDenied:
            return "Camera permission is required for scanning"
        case .insufficientWalls:
            return "Not enough walls detected. Please scan more of the room"
        case .fileSystemError(let reason):
            return "File system error: \(reason)"
        case .pdfGenerationFailed:
            return "Failed to generate PDF report"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .sessionFailed:
            return "Try restarting the scan in a well-lit area"
        case .exportFailed:
            return "Check available storage and try again"
        case .saveFailed:
            return "Check available storage and permissions"
        case .invalidRoom:
            return "Try scanning the room again with more coverage"
        case .lowQualityScan:
            return "Scan slowly and ensure all walls are captured"
        case .deviceNotSupported:
            return "Use an iPhone or iPad with LiDAR sensor"
        case .cameraPermissionDenied:
            return "Enable camera access in Settings"
        case .insufficientWalls:
            return "Point your device at all walls in the room"
        case .fileSystemError:
            return "Free up storage space and try again"
        case .pdfGenerationFailed:
            return "Try exporting without PDF report"
        }
    }

    var icon: String {
        switch self {
        case .sessionFailed, .invalidRoom:
            return "exclamationmark.triangle"
        case .exportFailed, .saveFailed, .fileSystemError:
            return "externaldrive.badge.exclamationmark"
        case .lowQualityScan, .insufficientWalls:
            return "waveform.path.ecg"
        case .deviceNotSupported:
            return "iphone.slash"
        case .cameraPermissionDenied:
            return "camera.fill"
        case .pdfGenerationFailed:
            return "doc.badge.exclamationmark"
        }
    }
}

// MARK: - Alert Item
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let showHelpButton: Bool

    init(error: RoomScanError) {
        self.title = "Error"
        self.message = error.errorDescription ?? "Unknown error"
        self.icon = error.icon
        self.showHelpButton = error.recoverySuggestion != nil
    }

    init(title: String, message: String, icon: String = "info.circle") {
        self.title = title
        self.message = message
        self.icon = icon
        self.showHelpButton = false
    }
}

// MARK: - Toast Message
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: Double

    enum ToastType {
        case success
        case error
        case warning
        case info

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    init(message: String, type: ToastType, duration: Double = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .foregroundColor(.white)
            Text(toast.message)
                .foregroundColor(.white)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(toast.type.color)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

// MARK: - Error Alert View Modifier
struct ErrorAlertModifier: ViewModifier {
    @Binding var alertItem: AlertItem?

    func body(content: Content) -> some View {
        content
            .alert(
                alertItem?.title ?? "Error",
                isPresented: Binding(
                    get: { alertItem != nil },
                    set: { if !$0 { alertItem = nil } }
                ),
                presenting: alertItem
            ) { _ in
                Button("OK", role: .cancel) { }
            } message: { item in
                Text(item.message)
            }
    }
}

// MARK: - View Extension
extension View {
    func errorAlert(alertItem: Binding<AlertItem?>) -> some View {
        modifier(ErrorAlertModifier(alertItem: alertItem))
    }
}

// MARK: - Quality Validation
struct QualityValidator {
    static func validate(measurements: RoomMeasurements) -> [RoomScanError] {
        var errors: [RoomScanError] = []

        if measurements.qualityScore < 50 {
            errors.append(.lowQualityScan(measurements.qualityScore))
        }

        if measurements.wallCount < 3 {
            errors.append(.insufficientWalls)
        }

        if measurements.totalFloorArea < 0.5 {
            errors.append(.invalidRoom)
        }

        return errors
    }

    static func getQualityFeedback(score: Int) -> (message: String, color: Color) {
        switch score {
        case 90...100:
            return ("Excellent scan quality!", .green)
        case 70..<90:
            return ("Good scan quality", .blue)
        case 50..<70:
            return ("Fair scan quality - consider rescanning", .orange)
        default:
            return ("Poor scan quality - please rescan", .red)
        }
    }
}
