//
//  RoomCaptureController.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 30/01/2024.
//  Updated with new features on 19/11/2025.
//

import Foundation
import RoomPlan
import Observation
import SwiftUI
import SwiftData

@Observable
class RoomCaptureController: RoomCaptureViewDelegate, RoomCaptureSessionDelegate, ObservableObject
{
    var roomCaptureView: RoomCaptureView
    var showExportButton = false
    var showShareSheet = false
    var exportUrl: URL?

    var sessionConfig: RoomCaptureSession.Configuration
    var finalResult: CapturedRoom?

    // New properties for enhanced features
    var currentMeasurements: RoomMeasurements = RoomMeasurements()
    var alertItem: AlertItem?
    var toastMessage: ToastMessage?
    var isProcessing = false
    var scanProgress: Double = 0
    var statusMessage = "Point your device at the room"

    // Multi-room support
    var isMultiRoomMode = false
    var scannedRooms: [CapturedRoom] = []
    var currentRoomIndex = 0

    // Export options
    var exportPDF = true
    var exportJSON = true
    var exportUSDZ = true

    // Scan name
    var scanName = "Room Scan"

    // Model context for SwiftData
    var modelContext: ModelContext?

    init() {
        roomCaptureView = RoomCaptureView(frame: CGRect(x: 0, y: 0, width: 42, height: 42))
        sessionConfig = RoomCaptureSession.Configuration()
        roomCaptureView.captureSession.delegate = self
        roomCaptureView.delegate = self
    }

    // MARK: - Session Management
    func startSession() {
        // Reset state
        showExportButton = false
        finalResult = nil
        currentMeasurements = RoomMeasurements()
        scanProgress = 0
        statusMessage = "Point your device at the room"

        // Configure session
        sessionConfig = RoomCaptureSession.Configuration()

        roomCaptureView.captureSession.run(configuration: sessionConfig)
    }

    func stopSession() {
        roomCaptureView.captureSession.stop()
    }

    // MARK: - Multi-room Support
    func startMultiRoomSession() {
        isMultiRoomMode = true
        scannedRooms = []
        currentRoomIndex = 0
        startSession()
    }

    func saveCurrentRoomAndContinue() {
        if let room = finalResult {
            scannedRooms.append(room)
            currentRoomIndex += 1
            toastMessage = ToastMessage(
                message: "Room \(currentRoomIndex) saved. Starting next room...",
                type: .success
            )
            startSession()
        }
    }

    func finishMultiRoomScan() {
        if let room = finalResult {
            scannedRooms.append(room)
        }
        isMultiRoomMode = false
        showExportButton = true
    }

    // MARK: - Delegate Methods
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        if let error = error {
            DispatchQueue.main.async {
                self.alertItem = AlertItem(
                    error: .sessionFailed(error.localizedDescription)
                )
            }
            return false
        }
        return true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.alertItem = AlertItem(
                    error: .sessionFailed(error.localizedDescription)
                )
            }
            return
        }

        finalResult = processedResult

        // Calculate measurements
        currentMeasurements = RoomMeasurementCalculator.calculate(from: processedResult)

        // Validate quality
        let validationErrors = QualityValidator.validate(measurements: currentMeasurements)
        if !validationErrors.isEmpty {
            let feedback = QualityValidator.getQualityFeedback(score: currentMeasurements.qualityScore)
            DispatchQueue.main.async {
                self.toastMessage = ToastMessage(
                    message: feedback.message,
                    type: self.currentMeasurements.qualityScore >= 50 ? .warning : .error
                )
            }
        }
    }

    // Session delegate for real-time updates
    func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        // Update measurements in real-time
        DispatchQueue.main.async {
            self.currentMeasurements = RoomMeasurementCalculator.calculate(from: room)
            self.updateProgress(room: room)
        }
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.alertItem = AlertItem(
                    error: .sessionFailed(error.localizedDescription)
                )
            }
        }
    }

    private func updateProgress(room: CapturedRoom) {
        // Estimate progress based on detected elements
        var progress = 0.0

        if room.walls.count >= 4 { progress += 0.4 }
        else { progress += Double(room.walls.count) * 0.1 }

        if room.doors.count > 0 { progress += 0.2 }
        if room.windows.count > 0 { progress += 0.1 }
        if room.objects.count > 0 { progress += min(0.3, Double(room.objects.count) * 0.05) }

        scanProgress = min(1.0, progress)

        // Update status message
        if room.walls.count < 3 {
            statusMessage = "Scan more walls (\(room.walls.count)/4)"
        } else if room.doors.count == 0 {
            statusMessage = "Looking for doors..."
        } else {
            statusMessage = "Good coverage! Keep scanning for details"
        }
    }

    // MARK: - Export Functions
    func export() {
        guard let result = finalResult else {
            alertItem = AlertItem(error: .invalidRoom)
            return
        }

        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            do {
                // Create export directory
                let scanId = UUID()
                let tempDir = FileManager.default.temporaryDirectory.appending(path: "Export_\(scanId.uuidString)")
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                var usdzData: Data?
                var jsonData: Data?
                var pdfData: Data?

                // Export USDZ
                if exportUSDZ {
                    let usdzURL = tempDir.appending(path: "Room.usdz")
                    try result.export(to: usdzURL, exportOptions: .parametric)
                    usdzData = try Data(contentsOf: usdzURL)
                }

                // Export JSON
                if exportJSON {
                    let jsonEncoder = JSONEncoder()
                    jsonEncoder.outputFormatting = .prettyPrinted
                    jsonData = try jsonEncoder.encode(result)
                    let jsonURL = tempDir.appending(path: "Room.json")
                    try jsonData?.write(to: jsonURL)
                }

                // Generate PDF report
                if exportPDF {
                    pdfData = PDFReportGenerator.generateReport(
                        roomName: scanName,
                        measurements: currentMeasurements,
                        scanDate: Date()
                    )
                    if let data = pdfData {
                        let pdfURL = tempDir.appending(path: "Report.pdf")
                        try data.write(to: pdfURL)
                    }
                }

                // Save to history
                if let context = modelContext {
                    let fileURLs = ScanHistoryManager.shared.saveScanFiles(
                        scanId: scanId,
                        usdzData: usdzData,
                        jsonData: jsonData,
                        pdfData: pdfData,
                        thumbnailImage: nil
                    )

                    let record = RoomScanRecord(
                        id: scanId,
                        name: scanName,
                        scanDate: Date(),
                        thumbnailData: fileURLs.thumbnailData,
                        usdzFileURL: fileURLs.usdzURL,
                        jsonFileURL: fileURLs.jsonURL,
                        pdfFileURL: fileURLs.pdfURL,
                        totalArea: currentMeasurements.totalFloorArea,
                        totalVolume: currentMeasurements.totalVolume,
                        wallCount: currentMeasurements.wallCount,
                        doorCount: currentMeasurements.doorCount,
                        windowCount: currentMeasurements.windowCount,
                        objectCount: currentMeasurements.objectCount,
                        roomWidth: currentMeasurements.roomWidth,
                        roomLength: currentMeasurements.roomLength,
                        roomHeight: currentMeasurements.roomHeight,
                        qualityScore: currentMeasurements.qualityScore
                    )

                    DispatchQueue.main.async {
                        context.insert(record)
                        try? context.save()
                    }
                }

                DispatchQueue.main.async {
                    self.exportUrl = tempDir
                    self.isProcessing = false
                    self.showShareSheet = true
                    self.toastMessage = ToastMessage(
                        message: "Export completed successfully!",
                        type: .success
                    )
                }

            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.alertItem = AlertItem(
                        error: .exportFailed(error.localizedDescription)
                    )
                }
            }
        }
    }

    // MARK: - Multi-room Export
    func exportAllRooms() {
        guard !scannedRooms.isEmpty else {
            alertItem = AlertItem(error: .invalidRoom)
            return
        }

        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            do {
                let exportDir = FileManager.default.temporaryDirectory.appending(path: "MultiRoomExport")
                try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)

                for (index, room) in scannedRooms.enumerated() {
                    let roomDir = exportDir.appending(path: "Room_\(index + 1)")
                    try FileManager.default.createDirectory(at: roomDir, withIntermediateDirectories: true)

                    // Export each room
                    let usdzURL = roomDir.appending(path: "Room.usdz")
                    try room.export(to: usdzURL, exportOptions: .parametric)

                    let jsonEncoder = JSONEncoder()
                    let jsonData = try jsonEncoder.encode(room)
                    let jsonURL = roomDir.appending(path: "Room.json")
                    try jsonData.write(to: jsonURL)

                    // Generate PDF
                    let measurements = RoomMeasurementCalculator.calculate(from: room)
                    if let pdfData = PDFReportGenerator.generateReport(
                        roomName: "Room \(index + 1)",
                        measurements: measurements,
                        scanDate: Date()
                    ) {
                        let pdfURL = roomDir.appending(path: "Report.pdf")
                        try pdfData.write(to: pdfURL)
                    }
                }

                DispatchQueue.main.async {
                    self.exportUrl = exportDir
                    self.isProcessing = false
                    self.showShareSheet = true
                }

            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.alertItem = AlertItem(
                        error: .exportFailed(error.localizedDescription)
                    )
                }
            }
        }
    }

    // MARK: - Utility
    func resetScan() {
        finalResult = nil
        currentMeasurements = RoomMeasurements()
        showExportButton = false
        showShareSheet = false
        exportUrl = nil
        scanProgress = 0
        scannedRooms = []
        isMultiRoomMode = false
    }

    required init?(coder: NSCoder) {
        fatalError("Not needed.")
    }

    func encode(with coder: NSCoder) {
        fatalError("Not needed.")
    }
}
