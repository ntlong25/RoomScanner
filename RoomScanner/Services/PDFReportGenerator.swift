//
//  PDFReportGenerator.swift
//  RoomScanner
//
//  Created by Claude on 19/11/2025.
//

import Foundation
import PDFKit
import UIKit
import RoomPlan

class PDFReportGenerator {

    static func generateReport(
        roomName: String,
        measurements: RoomMeasurements,
        scanDate: Date,
        thumbnailImage: UIImage? = nil
    ) -> Data? {

        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let pdfMetaData = [
            kCGPDFContextCreator: "RoomScanner",
            kCGPDFContextAuthor: "RoomScanner App",
            kCGPDFContextTitle: "Room Scan Report - \(roomName)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = margin

            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]

            let title = "Room Scan Report"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // Room name and date
            let subtitleFont = UIFont.systemFont(ofSize: 14)
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.darkGray
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short

            let subtitle = "\(roomName) - \(dateFormatter.string(from: scanDate))"
            subtitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: subtitleAttributes)
            yPosition += 30

            // Quality Score
            let qualityColor: UIColor = measurements.qualityScore >= 80 ? .systemGreen :
                                        measurements.qualityScore >= 60 ? .systemOrange : .systemRed
            let qualityAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: qualityColor
            ]
            let qualityText = "Quality Score: \(measurements.qualityScore)/100"
            qualityText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: qualityAttributes)
            yPosition += 40

            // Separator line
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: margin, y: yPosition))
            linePath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            UIColor.lightGray.setStroke()
            linePath.lineWidth = 1
            linePath.stroke()
            yPosition += 20

            // Section: Room Dimensions
            yPosition = drawSection(
                title: "Room Dimensions",
                yPosition: yPosition,
                margin: margin,
                pageWidth: pageWidth
            )

            let dimensionsData = [
                ("Width", String(format: "%.2f m", measurements.roomWidth)),
                ("Length", String(format: "%.2f m", measurements.roomLength)),
                ("Height", String(format: "%.2f m", measurements.roomHeight)),
                ("Floor Area", String(format: "%.2f m²", measurements.totalFloorArea)),
                ("Total Volume", String(format: "%.2f m³", measurements.totalVolume)),
                ("Wall Area", String(format: "%.2f m²", measurements.totalWallArea))
            ]

            for (label, value) in dimensionsData {
                yPosition = drawDataRow(
                    label: label,
                    value: value,
                    yPosition: yPosition,
                    margin: margin,
                    pageWidth: pageWidth
                )
            }

            yPosition += 20

            // Section: Room Elements
            yPosition = drawSection(
                title: "Room Elements",
                yPosition: yPosition,
                margin: margin,
                pageWidth: pageWidth
            )

            let elementsData = [
                ("Walls", "\(measurements.wallCount)"),
                ("Doors", "\(measurements.doorCount)"),
                ("Windows", "\(measurements.windowCount)"),
                ("Openings", "\(measurements.openingCount)"),
                ("Objects/Furniture", "\(measurements.objectCount)")
            ]

            for (label, value) in elementsData {
                yPosition = drawDataRow(
                    label: label,
                    value: value,
                    yPosition: yPosition,
                    margin: margin,
                    pageWidth: pageWidth
                )
            }

            // Page 2 - Wall Details
            if !measurements.wallDetails.isEmpty {
                context.beginPage()
                yPosition = margin

                yPosition = drawSection(
                    title: "Wall Details",
                    yPosition: yPosition,
                    margin: margin,
                    pageWidth: pageWidth
                )

                for wall in measurements.wallDetails {
                    let wallText = String(format: "Wall %d: %.2fm x %.2fm (Area: %.2f m²)",
                                         wall.index + 1, wall.width, wall.height, wall.area)
                    yPosition = drawDataRow(
                        label: "",
                        value: wallText,
                        yPosition: yPosition,
                        margin: margin,
                        pageWidth: pageWidth,
                        isFullWidth: true
                    )
                }
            }

            // Object Details
            if !measurements.objectDetails.isEmpty {
                yPosition += 20

                yPosition = drawSection(
                    title: "Detected Objects",
                    yPosition: yPosition,
                    margin: margin,
                    pageWidth: pageWidth
                )

                for object in measurements.objectDetails {
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = margin
                    }

                    let objectText = "\(object.category) - \(object.dimensions) [\(object.confidence)]"
                    yPosition = drawDataRow(
                        label: "",
                        value: objectText,
                        yPosition: yPosition,
                        margin: margin,
                        pageWidth: pageWidth,
                        isFullWidth: true
                    )
                }
            }

            // Footer
            let footerFont = UIFont.systemFont(ofSize: 10)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont,
                .foregroundColor: UIColor.gray
            ]
            let footer = "Generated by RoomScanner App"
            let footerSize = footer.size(withAttributes: footerAttributes)
            footer.draw(
                at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - margin),
                withAttributes: footerAttributes
            )
        }

        return data
    }

    private static func drawSection(
        title: String,
        yPosition: CGFloat,
        margin: CGFloat,
        pageWidth: CGFloat
    ) -> CGFloat {
        let sectionFont = UIFont.boldSystemFont(ofSize: 16)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.systemBlue
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
        return yPosition + 25
    }

    private static func drawDataRow(
        label: String,
        value: String,
        yPosition: CGFloat,
        margin: CGFloat,
        pageWidth: CGFloat,
        isFullWidth: Bool = false
    ) -> CGFloat {
        let labelFont = UIFont.systemFont(ofSize: 12)
        let valueFont = UIFont.systemFont(ofSize: 12, weight: .medium)

        if isFullWidth {
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: valueFont,
                .foregroundColor: UIColor.black
            ]
            value.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: valueAttributes)
        } else {
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: labelFont,
                .foregroundColor: UIColor.darkGray
            ]
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: valueFont,
                .foregroundColor: UIColor.black
            ]

            label.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: labelAttributes)
            value.draw(at: CGPoint(x: margin + 200, y: yPosition), withAttributes: valueAttributes)
        }

        return yPosition + 20
    }

    static func savePDF(data: Data, fileName: String, to directory: URL) -> URL? {
        let pdfURL = directory.appendingPathComponent(fileName)
        do {
            try data.write(to: pdfURL)
            return pdfURL
        } catch {
            print("Error saving PDF: \(error.localizedDescription)")
            return nil
        }
    }
}
