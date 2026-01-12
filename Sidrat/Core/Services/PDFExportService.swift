//
//  PDFExportService.swift
//  Sidrat
//
//  PDF Export Service for Parent Progress Dashboard (US-304)
//  Generates branded PDF reports with child progress data
//

import Foundation
import UIKit

/// Service for generating and exporting PDF progress reports
final class PDFExportService {
    
    // MARK: - Constants
    
    private enum PDFConstants {
        // Page dimensions (US Letter size: 8.5 x 11 inches at 72 DPI)
        static let pageWidth: CGFloat = 612
        static let pageHeight: CGFloat = 792
        static let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Margins
        static let marginLeft: CGFloat = 50
        static let marginRight: CGFloat = 50
        static let marginTop: CGFloat = 50
        static let marginBottom: CGFloat = 50
        
        // Content area
        static let contentWidth: CGFloat = pageWidth - marginLeft - marginRight
        
        // Spacing
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let smallSpacing: CGFloat = 6
        
        // Brand colors (UIColor for PDF rendering)
        static let brandPrimary = UIColor(red: 12/255, green: 116/255, blue: 137/255, alpha: 1) // #0C7489
        static let brandSecondary = UIColor(red: 72/255, green: 139/255, blue: 73/255, alpha: 1) // #488B49
        static let brandAccent = UIColor(red: 218/255, green: 165/255, blue: 32/255, alpha: 1) // #DAA520
        static let textPrimary = UIColor(red: 44/255, green: 62/255, blue: 63/255, alpha: 1) // #2C3E3F
        static let textSecondary = UIColor(red: 107/255, green: 112/255, blue: 128/255, alpha: 1) // #6B7280
        static let textTertiary = UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1) // #9CA3AF
        static let success = UIColor(red: 72/255, green: 139/255, blue: 73/255, alpha: 1) // Green
        static let backgroundLight = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1) // #F5F5F5
    }
    
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
        
        let renderer = UIGraphicsPDFRenderer(bounds: PDFConstants.pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            var currentY = PDFConstants.marginTop
            
            // Header section
            currentY = drawHeader(report: report, at: currentY, context: context)
            currentY += PDFConstants.sectionSpacing
            
            // Stats overview section
            currentY = drawStatsOverview(report: report, at: currentY, context: context)
            currentY += PDFConstants.sectionSpacing
            
            // Week comparison section
            currentY = drawWeekComparison(report: report, at: currentY, context: context)
            currentY += PDFConstants.sectionSpacing
            
            // Check if we need a new page
            if currentY > PDFConstants.pageHeight - 250 {
                drawFooter(report: report, context: context)
                context.beginPage()
                currentY = PDFConstants.marginTop
            }
            
            // Category progress section
            currentY = drawCategoryProgress(report: report, at: currentY, context: context)
            currentY += PDFConstants.sectionSpacing
            
            // Check if we need a new page for achievements
            if currentY > PDFConstants.pageHeight - 200 {
                drawFooter(report: report, context: context)
                context.beginPage()
                currentY = PDFConstants.marginTop
            }
            
            // Achievements section
            if !report.recentAchievements.isEmpty {
                currentY = drawAchievements(report: report, at: currentY, context: context)
            }
            
            // Footer
            drawFooter(report: report, context: context)
        }
        
        return data
    }
    
    // MARK: - Header Section
    
    private func drawHeader(report: ProgressReport, at startY: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = startY
        let marginLeft = PDFConstants.marginLeft
        
        // App logo/title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: PDFConstants.brandPrimary
        ]
        let titleString = "🌳 Sidrat Progress Report"
        let titleRect = CGRect(x: marginLeft, y: currentY, width: PDFConstants.contentWidth, height: 35)
        titleString.draw(in: titleRect, withAttributes: titleAttributes)
        currentY += 40
        
        // Child name and avatar indicator
        let childNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: PDFConstants.textPrimary
        ]
        let childNameString = "📚 \(report.childName)"
        let childRect = CGRect(x: marginLeft, y: currentY, width: PDFConstants.contentWidth, height: 28)
        childNameString.draw(in: childRect, withAttributes: childNameAttributes)
        currentY += 32
        
        // Report period and date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        let periodAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: PDFConstants.textSecondary
        ]
        let periodString = "Report Period: \(report.reportPeriod.rawValue) • Generated: \(dateFormatter.string(from: report.reportDate))"
        let periodRect = CGRect(x: marginLeft, y: currentY, width: PDFConstants.contentWidth, height: 20)
        periodString.draw(in: periodRect, withAttributes: periodAttributes)
        currentY += 24
        
        // Divider line
        currentY += 8
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: marginLeft, y: currentY))
        linePath.addLine(to: CGPoint(x: PDFConstants.pageWidth - PDFConstants.marginRight, y: currentY))
        PDFConstants.brandPrimary.withAlphaComponent(0.3).setStroke()
        linePath.lineWidth = 1.5
        linePath.stroke()
        currentY += 8
        
        return currentY
    }
    
    // MARK: - Stats Overview Section
    
    private func drawStatsOverview(report: ProgressReport, at startY: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = startY
        let marginLeft = PDFConstants.marginLeft
        
        // Section title
        currentY = drawSectionTitle("📊 Learning Overview", at: currentY)
        currentY += PDFConstants.itemSpacing
        
        // Stats grid (2x2)
        let boxWidth: CGFloat = (PDFConstants.contentWidth - 16) / 2
        let boxHeight: CGFloat = 70
        
        // Row 1
        drawStatBox(
            title: "Total Lessons",
            value: "\(report.totalLessonsCompleted)",
            icon: "📖",
            at: CGPoint(x: marginLeft, y: currentY),
            size: CGSize(width: boxWidth, height: boxHeight)
        )
        
        drawStatBox(
            title: "Total XP",
            value: "\(report.totalXP)",
            icon: "⭐",
            at: CGPoint(x: marginLeft + boxWidth + 16, y: currentY),
            size: CGSize(width: boxWidth, height: boxHeight)
        )
        currentY += boxHeight + 12
        
        // Row 2
        drawStatBox(
            title: "Current Streak",
            value: "\(report.currentStreak) days",
            icon: "🔥",
            at: CGPoint(x: marginLeft, y: currentY),
            size: CGSize(width: boxWidth, height: boxHeight)
        )
        
        drawStatBox(
            title: "Learning Time",
            value: report.formattedLearningTime,
            icon: "⏱️",
            at: CGPoint(x: marginLeft + boxWidth + 16, y: currentY),
            size: CGSize(width: boxWidth, height: boxHeight)
        )
        currentY += boxHeight
        
        return currentY
    }
    
    private func drawStatBox(title: String, value: String, icon: String, at origin: CGPoint, size: CGSize) {
        // Background
        let boxRect = CGRect(origin: origin, size: size)
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        PDFConstants.backgroundLight.setFill()
        boxPath.fill()
        
        // Border
        PDFConstants.brandPrimary.withAlphaComponent(0.2).setStroke()
        boxPath.lineWidth = 1
        boxPath.stroke()
        
        // Icon and value
        let iconValueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: PDFConstants.brandPrimary
        ]
        let iconValueString = "\(icon) \(value)"
        let iconValueRect = CGRect(x: origin.x + 12, y: origin.y + 12, width: size.width - 24, height: 28)
        iconValueString.draw(in: iconValueRect, withAttributes: iconValueAttributes)
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: PDFConstants.textSecondary
        ]
        let titleRect = CGRect(x: origin.x + 12, y: origin.y + 44, width: size.width - 24, height: 18)
        title.draw(in: titleRect, withAttributes: titleAttributes)
    }
    
    // MARK: - Week Comparison Section
    
    private func drawWeekComparison(report: ProgressReport, at startY: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = startY
        let marginLeft = PDFConstants.marginLeft
        
        // Section title
        currentY = drawSectionTitle("📈 Weekly Progress", at: currentY)
        currentY += PDFConstants.itemSpacing
        
        let comparison = report.weekComparison
        
        // Comparison boxes
        let boxWidth: CGFloat = (PDFConstants.contentWidth - 32) / 3
        let boxHeight: CGFloat = 60
        
        // This week
        drawComparisonBox(
            title: "This Week",
            value: "\(comparison.thisWeekCount)",
            subtitle: "lessons",
            highlight: true,
            at: CGPoint(x: marginLeft, y: currentY),
            size: CGSize(width: boxWidth, height: boxHeight)
        )
        
        // Trend indicator
        let trendIcon: String
        let trendColor: UIColor
        switch comparison.trend {
        case .improving:
            trendIcon = "↑"
            trendColor = PDFConstants.success
        case .declining:
            trendIcon = "↓"
            trendColor = UIColor.systemOrange
        case .stable:
            trendIcon = "→"
            trendColor = PDFConstants.brandPrimary
        }
        
        let trendAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: trendColor
        ]
        let trendRect = CGRect(x: marginLeft + boxWidth + 4, y: currentY + 15, width: 24, height: 30)
        trendIcon.draw(in: trendRect, withAttributes: trendAttributes)
        
        // Last week
        drawComparisonBox(
            title: "Last Week",
            value: "\(comparison.lastWeekCount)",
            subtitle: "lessons",
            highlight: false,
            at: CGPoint(x: marginLeft + boxWidth + 32, y: currentY),
            size: CGSize(width: boxWidth, height: boxHeight)
        )
        
        // Change indicator
        let changeString = comparison.shortDescription
        let changeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: trendColor
        ]
        let changeRect = CGRect(x: marginLeft + (boxWidth * 2) + 48, y: currentY + 20, width: boxWidth, height: 20)
        changeString.draw(in: changeRect, withAttributes: changeAttributes)
        
        currentY += boxHeight + 12
        
        // Motivational message
        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 13),
            .foregroundColor: PDFConstants.textSecondary
        ]
        let messageRect = CGRect(x: marginLeft, y: currentY, width: PDFConstants.contentWidth, height: 20)
        comparison.message.draw(in: messageRect, withAttributes: messageAttributes)
        currentY += 20
        
        return currentY
    }
    
    private func drawComparisonBox(title: String, value: String, subtitle: String, highlight: Bool, at origin: CGPoint, size: CGSize) {
        // Background
        let boxRect = CGRect(origin: origin, size: size)
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
        
        if highlight {
            PDFConstants.brandPrimary.withAlphaComponent(0.1).setFill()
            PDFConstants.brandPrimary.setStroke()
        } else {
            PDFConstants.backgroundLight.setFill()
            PDFConstants.textTertiary.setStroke()
        }
        boxPath.fill()
        boxPath.lineWidth = 1
        boxPath.stroke()
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: PDFConstants.textSecondary
        ]
        let titleRect = CGRect(x: origin.x + 8, y: origin.y + 6, width: size.width - 16, height: 14)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Value
        let valueColor = highlight ? PDFConstants.brandPrimary : PDFConstants.textPrimary
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: valueColor
        ]
        let valueRect = CGRect(x: origin.x + 8, y: origin.y + 20, width: size.width - 16, height: 24)
        value.draw(in: valueRect, withAttributes: valueAttributes)
        
        // Subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: PDFConstants.textTertiary
        ]
        let subtitleRect = CGRect(x: origin.x + 8, y: origin.y + 42, width: size.width - 16, height: 14)
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
    }
    
    // MARK: - Category Progress Section
    
    private func drawCategoryProgress(report: ProgressReport, at startY: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = startY
        let marginLeft = PDFConstants.marginLeft
        
        // Section title
        currentY = drawSectionTitle("📚 Category Progress", at: currentY)
        currentY += PDFConstants.itemSpacing
        
        // Filter categories that have some content
        let categories = report.sortedCategoryProgress
        
        if categories.isEmpty {
            // No categories message
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 12),
                .foregroundColor: PDFConstants.textSecondary
            ]
            let noDataRect = CGRect(x: marginLeft, y: currentY, width: PDFConstants.contentWidth, height: 18)
            "No category progress to display yet.".draw(in: noDataRect, withAttributes: noDataAttributes)
            currentY += 20
            return currentY
        }
        
        // Draw each category with progress bar
        for stats in categories {
            currentY = drawCategoryProgressRow(stats: stats, at: currentY)
            currentY += PDFConstants.itemSpacing
        }
        
        return currentY
    }
    
    private func drawCategoryProgressRow(stats: CategoryStats, at y: CGFloat) -> CGFloat {
        let marginLeft = PDFConstants.marginLeft
        let rowHeight: CGFloat = 36
        
        // Category name attributes
        let categoryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: PDFConstants.textPrimary
        ]
        
        // Get emoji for category
        let categoryEmoji: String
        switch stats.category {
        case .aqeedah: categoryEmoji = "⭐"
        case .salah: categoryEmoji = "🙏"
        case .wudu: categoryEmoji = "💧"
        case .quran: categoryEmoji = "📖"
        case .seerah: categoryEmoji = "🕌"
        case .adab: categoryEmoji = "❤️"
        case .duaa: categoryEmoji = "🤲"
        case .stories: categoryEmoji = "📚"
        }
        
        let categoryString = "\(categoryEmoji) \(stats.category.rawValue)"
        let categoryRect = CGRect(x: marginLeft, y: y, width: 120, height: 18)
        categoryString.draw(in: categoryRect, withAttributes: categoryAttributes)
        
        // Progress bar
        let barX = marginLeft + 130
        let barY = y + 2
        let barWidth: CGFloat = PDFConstants.contentWidth - 200
        let barHeight: CGFloat = 14
        
        // Background bar
        let bgPath = UIBezierPath(roundedRect: CGRect(x: barX, y: barY, width: barWidth, height: barHeight), cornerRadius: 7)
        PDFConstants.backgroundLight.setFill()
        bgPath.fill()
        
        // Progress fill
        let progressWidth = barWidth * CGFloat(stats.completionPercentage)
        if progressWidth > 0 {
            let progressPath = UIBezierPath(roundedRect: CGRect(x: barX, y: barY, width: max(progressWidth, 14), height: barHeight), cornerRadius: 7)
            PDFConstants.brandPrimary.setFill()
            progressPath.fill()
        }
        
        // Percentage text
        let percentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: PDFConstants.brandPrimary
        ]
        let percentString = stats.formattedPercentage
        let percentRect = CGRect(x: barX + barWidth + 12, y: y, width: 50, height: 18)
        percentString.draw(in: percentRect, withAttributes: percentAttributes)
        
        // Count text
        let countAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: PDFConstants.textSecondary
        ]
        let countString = "\(stats.completedCount)/\(stats.totalCount)"
        let countRect = CGRect(x: marginLeft, y: y + 18, width: 120, height: 14)
        countString.draw(in: countRect, withAttributes: countAttributes)
        
        return y + rowHeight
    }
    
    // MARK: - Achievements Section
    
    private func drawAchievements(report: ProgressReport, at startY: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = startY
        let marginLeft = PDFConstants.marginLeft
        
        // Section title
        currentY = drawSectionTitle("🏆 Recent Achievements", at: currentY)
        currentY += PDFConstants.itemSpacing
        
        // Draw achievements in a grid (3 per row)
        let achievementsPerRow = 3
        let badgeWidth: CGFloat = (PDFConstants.contentWidth - CGFloat(achievementsPerRow - 1) * 12) / CGFloat(achievementsPerRow)
        let badgeHeight: CGFloat = 60
        
        let achievements = report.recentAchievements.prefix(6) // Limit to 6 for space
        
        for (index, achievementType) in achievements.enumerated() {
            let row = index / achievementsPerRow
            let col = index % achievementsPerRow
            
            let x = marginLeft + CGFloat(col) * (badgeWidth + 12)
            let y = currentY + CGFloat(row) * (badgeHeight + 8)
            
            drawAchievementBadge(achievementType: achievementType, at: CGPoint(x: x, y: y), size: CGSize(width: badgeWidth, height: badgeHeight))
        }
        
        let rows = (achievements.count + achievementsPerRow - 1) / achievementsPerRow
        currentY += CGFloat(rows) * (badgeHeight + 8)
        
        return currentY
    }
    
    private func drawAchievementBadge(achievementType: AchievementType, at origin: CGPoint, size: CGSize) {
        // Background
        let boxRect = CGRect(origin: origin, size: size)
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
        PDFConstants.brandAccent.withAlphaComponent(0.15).setFill()
        boxPath.fill()
        
        // Border
        PDFConstants.brandAccent.setStroke()
        boxPath.lineWidth = 1
        boxPath.stroke()
        
        // Trophy icon
        let iconAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22)
        ]
        let iconRect = CGRect(x: origin.x + 8, y: origin.y + 8, width: 30, height: 28)
        "🏅".draw(in: iconRect, withAttributes: iconAttributes)
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: PDFConstants.textPrimary
        ]
        let titleRect = CGRect(x: origin.x + 8, y: origin.y + 36, width: size.width - 16, height: 16)
        achievementType.title.draw(in: titleRect, withAttributes: titleAttributes)
    }
    
    // MARK: - Footer Section
    
    private func drawFooter(report: ProgressReport, context: UIGraphicsPDFRendererContext) {
        let marginLeft = PDFConstants.marginLeft
        let footerY = PDFConstants.pageHeight - PDFConstants.marginBottom + 10
        
        // Divider line
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: marginLeft, y: footerY - 15))
        linePath.addLine(to: CGPoint(x: PDFConstants.pageWidth - PDFConstants.marginRight, y: footerY - 15))
        PDFConstants.textTertiary.withAlphaComponent(0.3).setStroke()
        linePath.lineWidth = 0.5
        linePath.stroke()
        
        // Footer text
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: PDFConstants.textTertiary
        ]
        
        // Left side: App info
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let leftText = "Sidrat Learning v\(appVersion) • sidratlearning.com"
        let leftRect = CGRect(x: marginLeft, y: footerY, width: 200, height: 14)
        leftText.draw(in: leftRect, withAttributes: footerAttributes)
        
        // Right side: Timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        let rightText = "Generated: \(dateFormatter.string(from: Date()))"
        
        let rightAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: PDFConstants.textTertiary
        ]
        
        let textSize = rightText.size(withAttributes: rightAttributes)
        let rightRect = CGRect(
            x: PDFConstants.pageWidth - PDFConstants.marginRight - textSize.width,
            y: footerY,
            width: textSize.width,
            height: 14
        )
        rightText.draw(in: rightRect, withAttributes: rightAttributes)
    }
    
    // MARK: - Helpers
    
    private func drawSectionTitle(_ title: String, at y: CGFloat) -> CGFloat {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: PDFConstants.textPrimary
        ]
        let titleRect = CGRect(x: PDFConstants.marginLeft, y: y, width: PDFConstants.contentWidth, height: 22)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        return y + 22
    }
    
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
