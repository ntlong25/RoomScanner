//
//  Model.swift
//  RoomScanner
//
//  Created by Nguyen Thanh Long on 30/01/2024.
//

import Foundation
import RoomPlan
import Observation

@Observable
class RoomCaptureController: RoomCaptureViewDelegate, RoomCaptureSessionDelegate, ObservableObject
{
    var roomCaptureView: RoomCaptureView
    var showExportButton = false
    var showShareSheet = false
    var exportUrl: URL?
    
    var sessionConfig: RoomCaptureSession.Configuration
    var finalResult: CapturedRoom?
    
    init() {
        roomCaptureView = RoomCaptureView(frame: CGRect(x: 0, y: 0, width: 42, height: 42))
        sessionConfig = RoomCaptureSession.Configuration()
        roomCaptureView.captureSession.delegate = self
        roomCaptureView.delegate = self
    }
    
    func startSession() {
        roomCaptureView.captureSession.run(configuration: sessionConfig)
    }
    
    func stopSession() {
        roomCaptureView.captureSession.stop()
    }
    
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }
    
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let err = error {
            print("Error: \(err.localizedDescription)")
        }
        finalResult = processedResult
    }
    
    func export() {
        exportUrl = FileManager.default.temporaryDirectory.appending(path: "Export")
        guard let destinationURL = exportUrl?.appending(path: "Room.usdz") else { return }
        guard let capturedRoomURL = exportUrl?.appending(path: "Room.json") else { return }
        do {
            try FileManager.default.createDirectory(at: exportUrl!, withIntermediateDirectories: true)
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(finalResult)
            try jsonData.write(to: capturedRoomURL)
            try finalResult?.export(to: destinationURL, exportOptions: .parametric)
        } catch {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        showShareSheet = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not needed.")
    }
    
    func encode(with coder: NSCoder) {
        fatalError("Not needed.")
    }
}
