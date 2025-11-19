//
//  ScanHistoryManager.swift
//  RoomScanner
//
//  Created by Claude on 19/11/2025.
//

import Foundation
import SwiftData
import UIKit

class ScanHistoryManager {

    static let shared = ScanHistoryManager()

    private let fileManager = FileManager.default
    private let scansDirectory: URL

    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        scansDirectory = documentsPath.appendingPathComponent("RoomScans", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: scansDirectory.path) {
            try? fileManager.createDirectory(at: scansDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Save Scan Files
    func saveScanFiles(
        scanId: UUID,
        usdzData: Data?,
        jsonData: Data?,
        pdfData: Data?,
        thumbnailImage: UIImage?
    ) -> (usdzURL: String?, jsonURL: String?, pdfURL: String?, thumbnailData: Data?) {

        let scanFolder = scansDirectory.appendingPathComponent(scanId.uuidString, isDirectory: true)

        do {
            try fileManager.createDirectory(at: scanFolder, withIntermediateDirectories: true)
        } catch {
            print("Error creating scan folder: \(error)")
            return (nil, nil, nil, nil)
        }

        var usdzURL: String?
        var jsonURL: String?
        var pdfURL: String?
        var thumbnailData: Data?

        // Save USDZ
        if let data = usdzData {
            let url = scanFolder.appendingPathComponent("Room.usdz")
            do {
                try data.write(to: url)
                usdzURL = url.path
            } catch {
                print("Error saving USDZ: \(error)")
            }
        }

        // Save JSON
        if let data = jsonData {
            let url = scanFolder.appendingPathComponent("Room.json")
            do {
                try data.write(to: url)
                jsonURL = url.path
            } catch {
                print("Error saving JSON: \(error)")
            }
        }

        // Save PDF
        if let data = pdfData {
            let url = scanFolder.appendingPathComponent("Report.pdf")
            do {
                try data.write(to: url)
                pdfURL = url.path
            } catch {
                print("Error saving PDF: \(error)")
            }
        }

        // Save thumbnail
        if let image = thumbnailImage {
            thumbnailData = image.jpegData(compressionQuality: 0.7)
        }

        return (usdzURL, jsonURL, pdfURL, thumbnailData)
    }

    // MARK: - Delete Scan Files
    func deleteScanFiles(scanId: UUID) {
        let scanFolder = scansDirectory.appendingPathComponent(scanId.uuidString, isDirectory: true)
        try? fileManager.removeItem(at: scanFolder)
    }

    // MARK: - Get File URLs
    func getFileURLs(for scan: RoomScanRecord) -> [URL] {
        var urls: [URL] = []

        if let path = scan.usdzFileURL {
            urls.append(URL(fileURLWithPath: path))
        }
        if let path = scan.jsonFileURL {
            urls.append(URL(fileURLWithPath: path))
        }
        if let path = scan.pdfFileURL {
            urls.append(URL(fileURLWithPath: path))
        }

        return urls
    }

    // MARK: - Get Scan Folder URL
    func getScanFolder(for scanId: UUID) -> URL {
        return scansDirectory.appendingPathComponent(scanId.uuidString, isDirectory: true)
    }

    // MARK: - Check if files exist
    func filesExist(for scan: RoomScanRecord) -> Bool {
        if let path = scan.usdzFileURL {
            return fileManager.fileExists(atPath: path)
        }
        return false
    }

    // MARK: - Get total storage used
    func getTotalStorageUsed() -> Int64 {
        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: scansDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        return totalSize
    }

    // MARK: - Format storage size
    static func formatStorageSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
