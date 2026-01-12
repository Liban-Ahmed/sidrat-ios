//
//  PDFExportService.swift
//  Sidrat
//
//  PDF Export Service for Parent Progress Dashboard (US-304)
//  Orchestrates PDF generation using PDFSectionRenderer
//

import Foundation
import UIKit

/// Service for generating and exporting PDF progress reports
/// Delegates rendering to PDFSectionRenderer to maintain line limits
final class PDFExportService {
    
    // MARK: - Export Result
    
    enum ExportResult {
        case success(URL)
        case failure(ExportError)
    }
    
    enum ExportError: LocalizedError {
        case noReportData
        case pdfGenerationFailed
        case fileWriteFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .noReportData:
                return "No report data available to export"
            case .pdfGenerationFailed:
                return "Failed to generate PDF document"
            case .fileWriteFailed(let error):
                return "Failed to save PDF: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Export a progress report to PDF and return the file URL
    /// - Parameter report: The progress report to export
    /// - Returns: Result containing the file URL or error
    func exportProgressReport(_ report: ProgressReport) -> ExportResult {
        #if DEBUG
        print("[PDFExportService] Starting PDF export for \(report.childName)")
        #endif
        
        // Generate PDF data
        let pdfData = generatePDF(for: report)
        
        guard !pdfData.isEmpty else {
            return .failure(.pdfGenerationFailed)
        }
        
        // Save to documents directory
        guard let fileURL = savePDFToDocuments(pdfData, childName: report.childName, reportDate: report.reportDate) else {
            return .failure(.pdfGenerationFailed)
        }
        
        #if DEBUG
        print("[PDFExportService] PDF saved to: \(fileURL.path)")
        #endif
        
        return .success(fileURL)
    }
    
    // MARK: - PDF Generation
    
    private func generatePDF(for report: ProgressReport) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Sidrat Progress Report - \(report.childName)",
            kCGPDFContextAuthor as String: "Sidrat Learning",
            kCGPDFContextCreator as String: "Sidrat iOS App"
        ]
        
        let renderer = UIGraphicsPDFRenderer(bounds: PDFSectionRenderer.PDFConstants.pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            var currentY = PDFSectionRenderer.PDFConstants.marginTop
            
            // Header section
            currentY = PDFSectionRenderer.drawHeader(report: report, at: currentY, context: context)
            currentY += PDFSectionRenderer.PDFConstants.sectionSpacing
            
            // Stats overview section
            currentY = PDFSectionRenderer.drawStatsOverview(report: report, at: currentY, context: context)
            currentY += PDFSectionRenderer.PDFConstants.sectionSpacing
            
            // Week comparison section
            currentY = PDFSectionRenderer.drawWeekComparison(report: report, at: currentY, context: context)
            currentY += PDFSectionRenderer.PDFConstants.sectionSpacing
            
            // Check if we need a new page
            if currentY > PDFSectionRenderer.PDFConstants.pageHeight - 250 {
                PDFSectionRenderer.drawFooter(report: report, context: context)
                context.beginPage()
                currentY = PDFSectionRenderer.PDFConstants.marginTop
            }
            
            // Category progress section
            currentY = PDFSectionRenderer.drawCategoryProgress(report: report, at: currentY, context: context)
            currentY += PDFSectionRenderer.PDFConstants.sectionSpacing
            
            // Check if we need a new page for achievements
            if currentY > PDFSectionRenderer.PDFConstants.pageHeight - 200 {
                PDFSectionRenderer.drawFooter(report: report, context: context)
                context.beginPage()
                currentY = PDFSectionRenderer.PDFConstants.marginTop
            }
            
            // Achievements section
            if !report.recentAchievements.isEmpty {
                currentY = PDFSectionRenderer.drawAchievements(report: report, at: currentY, context: context)
            }
            
            // Footer
            PDFSectionRenderer.drawFooter(report: report, context: context)
        }
        
        return data
    }
    
    // MARK: - File Management
    
    private func savePDFToDocuments(_ data: Data, childName: String, reportDate: Date) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: reportDate)
        
        // Sanitize child name for filename
        let sanitizedName = childName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        
        let fileName = "Sidrat_Progress_\(sanitizedName)_\(dateString).pdf"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            #if DEBUG
            print("[PDFExportService] Error saving PDF: \(error)")
            #endif
            return nil
        }
    }
}
