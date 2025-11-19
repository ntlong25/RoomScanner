//
//  RoomScanModel.swift
//  RoomScanner
//
//  Created by Claude on 19/11/2025.
//

import Foundation
import SwiftData
import RoomPlan

// MARK: - SwiftData Model for persistence
@Model
final class RoomScanRecord {
    var id: UUID
    var name: String
    var scanDate: Date
    var thumbnailData: Data?
    var usdzFileURL: String?
    var jsonFileURL: String?
    var pdfFileURL: String?

    // Room measurements
    var totalArea: Double
    var totalVolume: Double
    var wallCount: Int
    var doorCount: Int
    var windowCount: Int
    var objectCount: Int

    // Dimensions
    var roomWidth: Double
    var roomLength: Double
    var roomHeight: Double

    // Quality score (0-100)
    var qualityScore: Int

    // Notes
    var notes: String

    init(
        id: UUID = UUID(),
        name: String = "Untitled Scan",
        scanDate: Date = Date(),
        thumbnailData: Data? = nil,
        usdzFileURL: String? = nil,
        jsonFileURL: String? = nil,
        pdfFileURL: String? = nil,
        totalArea: Double = 0,
        totalVolume: Double = 0,
        wallCount: Int = 0,
        doorCount: Int = 0,
        windowCount: Int = 0,
        objectCount: Int = 0,
        roomWidth: Double = 0,
        roomLength: Double = 0,
        roomHeight: Double = 0,
        qualityScore: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.scanDate = scanDate
        self.thumbnailData = thumbnailData
        self.usdzFileURL = usdzFileURL
        self.jsonFileURL = jsonFileURL
        self.pdfFileURL = pdfFileURL
        self.totalArea = totalArea
        self.totalVolume = totalVolume
        self.wallCount = wallCount
        self.doorCount = doorCount
        self.windowCount = windowCount
        self.objectCount = objectCount
        self.roomWidth = roomWidth
        self.roomLength = roomLength
        self.roomHeight = roomHeight
        self.qualityScore = qualityScore
        self.notes = notes
    }
}

// MARK: - Room Measurements
struct RoomMeasurements {
    var totalFloorArea: Double = 0
    var totalWallArea: Double = 0
    var totalVolume: Double = 0
    var roomWidth: Double = 0
    var roomLength: Double = 0
    var roomHeight: Double = 0
    var wallCount: Int = 0
    var doorCount: Int = 0
    var windowCount: Int = 0
    var openingCount: Int = 0
    var objectCount: Int = 0
    var objectDetails: [ObjectDetail] = []
    var wallDetails: [WallDetail] = []
    var qualityScore: Int = 0
}

struct ObjectDetail: Identifiable {
    let id = UUID()
    let category: String
    let dimensions: String
    let confidence: String
}

struct WallDetail: Identifiable {
    let id = UUID()
    let index: Int
    let width: Double
    let height: Double
    let area: Double
}

// MARK: - Room Measurement Calculator
class RoomMeasurementCalculator {

    static func calculate(from room: CapturedRoom) -> RoomMeasurements {
        var measurements = RoomMeasurements()

        // Count elements
        measurements.wallCount = room.walls.count
        measurements.doorCount = room.doors.count
        measurements.windowCount = room.windows.count
        measurements.openingCount = room.openings.count
        measurements.objectCount = room.objects.count

        // Calculate room bounds
        var minX: Float = .infinity
        var maxX: Float = -.infinity
        var minY: Float = .infinity
        var maxY: Float = -.infinity
        var minZ: Float = .infinity
        var maxZ: Float = -.infinity

        // Process walls
        var totalWallArea: Double = 0
        var wallIndex = 0

        for wall in room.walls {
            let dimensions = wall.dimensions
            let wallArea = Double(dimensions.x * dimensions.y)
            totalWallArea += wallArea

            let wallDetail = WallDetail(
                index: wallIndex,
                width: Double(dimensions.x),
                height: Double(dimensions.y),
                area: wallArea
            )
            measurements.wallDetails.append(wallDetail)
            wallIndex += 1

            // Update bounds
            let transform = wall.transform
            let position = simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)

            minX = min(minX, position.x - dimensions.x/2)
            maxX = max(maxX, position.x + dimensions.x/2)
            minY = min(minY, position.y - dimensions.y/2)
            maxY = max(maxY, position.y + dimensions.y/2)
            minZ = min(minZ, position.z - dimensions.z/2)
            maxZ = max(maxZ, position.z + dimensions.z/2)
        }

        measurements.totalWallArea = totalWallArea

        // Calculate room dimensions
        if room.walls.count > 0 {
            measurements.roomWidth = Double(maxX - minX)
            measurements.roomLength = Double(maxZ - minZ)
            measurements.roomHeight = Double(maxY - minY)

            // Calculate floor area and volume
            measurements.totalFloorArea = measurements.roomWidth * measurements.roomLength
            measurements.totalVolume = measurements.totalFloorArea * measurements.roomHeight
        }

        // Process objects
        for object in room.objects {
            let dimensions = object.dimensions
            let dimensionStr = String(format: "%.2fm x %.2fm x %.2fm", dimensions.x, dimensions.y, dimensions.z)

            let confidence: String
            switch object.confidence {
            case .high:
                confidence = "High"
            case .medium:
                confidence = "Medium"
            case .low:
                confidence = "Low"
            @unknown default:
                confidence = "Unknown"
            }

            let detail = ObjectDetail(
                category: object.category.description,
                dimensions: dimensionStr,
                confidence: confidence
            )
            measurements.objectDetails.append(detail)
        }

        // Calculate quality score
        measurements.qualityScore = calculateQualityScore(room: room, measurements: measurements)

        return measurements
    }

    private static func calculateQualityScore(room: CapturedRoom, measurements: RoomMeasurements) -> Int {
        var score = 100

        // Deduct points for low confidence objects
        let lowConfidenceCount = room.objects.filter { $0.confidence == .low }.count
        score -= lowConfidenceCount * 5

        // Deduct points if too few walls detected
        if measurements.wallCount < 4 {
            score -= (4 - measurements.wallCount) * 10
        }

        // Deduct points if room dimensions seem unrealistic
        if measurements.roomHeight < 2.0 || measurements.roomHeight > 5.0 {
            score -= 10
        }

        if measurements.totalFloorArea < 1.0 {
            score -= 20
        }

        // Bonus for detecting doors and windows
        if measurements.doorCount > 0 {
            score += 5
        }
        if measurements.windowCount > 0 {
            score += 5
        }

        return max(0, min(100, score))
    }
}

// MARK: - CapturedRoom.Object.Category Extension
extension CapturedRoom.Object.Category: CustomStringConvertible {
    public var description: String {
        switch self {
        case .storage: return "Storage"
        case .refrigerator: return "Refrigerator"
        case .stove: return "Stove"
        case .bed: return "Bed"
        case .sink: return "Sink"
        case .washerDryer: return "Washer/Dryer"
        case .toilet: return "Toilet"
        case .bathtub: return "Bathtub"
        case .oven: return "Oven"
        case .dishwasher: return "Dishwasher"
        case .table: return "Table"
        case .sofa: return "Sofa"
        case .chair: return "Chair"
        case .fireplace: return "Fireplace"
        case .television: return "Television"
        case .stairs: return "Stairs"
        @unknown default: return "Unknown"
        }
    }
}
