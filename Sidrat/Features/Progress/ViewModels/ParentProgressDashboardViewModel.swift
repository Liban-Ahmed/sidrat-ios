//
//  ParentProgressDashboardViewModel.swift
//  Sidrat
//
//  ViewModel for Parent Progress Dashboard (US-304)
//  Manages report generation, child selection, and export functionality
//

import SwiftUI
import SwiftData

@Observable
final class ParentProgressDashboardViewModel {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let reportService: ProgressReportService
    private let pdfService: PDFExportService
    
    // MARK: - Published State
    
    /// The currently selected child for the report
    var selectedChild: Child?
    
    /// The selected report period
    var selectedPeriod: ReportPeriod = .thisWeek
    
    /// The current progress report (nil if not yet generated)
    var currentReport: ProgressReport?
    
    /// Loading state for report generation
    var isLoadingReport = false
    
    /// Error message if report generation fails
    var errorMessage: String?
    
    // MARK: - Export State
    
    /// Whether the share sheet is showing
    var showShareSheet = false
    
    /// URL of the exported PDF (if successfully generated)
    var exportedPDFURL: URL?
    
    /// Loading state for PDF export
    var isExporting = false
    
    /// Error message if export fails
    var exportError: String?
    
    // MARK: - Computed Properties
    
    /// Whether there are multiple children to choose from
    var hasMultipleChildren: Bool {
        allChildren.count > 1
    }
    
    /// All children available for selection
    private(set) var allChildren: [Child] = []
    
    /// Current week comparison data (convenience accessor)
    var weekComparison: WeekComparison? {
        currentReport?.weekComparison
    }
    
    /// Category progress sorted by completion (convenience accessor)
    var sortedCategoryProgress: [CategoryStats] {
        currentReport?.sortedCategoryProgress ?? []
    }
    
    /// Whether the current report has enough data to display
    var hasEnoughData: Bool {
        currentReport?.hasEnoughData ?? false
    }
    
    /// Trend from week comparison (for UI display)
    var currentTrend: Trend {
        weekComparison?.trend ?? .stable
    }
    
    /// Motivational message based on current trend
    var motivationalMessage: String {
        weekComparison?.message ?? "Start learning to track your progress!"
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.reportService = ProgressReportService(modelContext: modelContext)
        self.pdfService = PDFExportService()
    }
    
    /// Initialize with a specific child pre-selected
    init(modelContext: ModelContext, child: Child) {
        self.modelContext = modelContext
        self.reportService = ProgressReportService(modelContext: modelContext)
        self.pdfService = PDFExportService()
        self.selectedChild = child
    }
    
    // MARK: - Setup
    
    /// Load children and set up initial state
    /// Call this when the view appears
    func setup(children: [Child], currentChildId: String?) {
        self.allChildren = children
        
        // If we don't have a selected child, try to find one
        if selectedChild == nil {
            if let currentId = currentChildId,
               let uuid = UUID(uuidString: currentId),
               let child = children.first(where: { $0.id == uuid }) {
                selectedChild = child
            } else {
                selectedChild = children.first
            }
        }
        
        // Load report for the selected child
        if selectedChild != nil {
            loadReport()
        }
    }
    
    // MARK: - Report Loading
    
    /// Load the progress report for the currently selected child
    func loadReport() {
        guard let child = selectedChild else {
            errorMessage = "Please select a child profile"
            currentReport = nil
            return
        }
        
        isLoadingReport = true
        errorMessage = nil
        
        // Generate report (this is synchronous but fast with caching)
        // For very large datasets, consider moving to async
        let report = reportService.generateReport(for: child, period: selectedPeriod)
        
        currentReport = report
        isLoadingReport = false
        
        #if DEBUG
        print("[ParentProgressDashboardViewModel] Report loaded for \(child.name)")
        print("  - Total lessons: \(report.totalLessonsCompleted)")
        print("  - Period lessons: \(report.periodLessonsCompleted)")
        print("  - Categories: \(report.categoryProgress.count)")
        #endif
    }
    
    /// Refresh the report (invalidates cache first)
    func refreshReport() {
        guard let child = selectedChild else { return }
        
        // Invalidate cache for this child
        reportService.invalidateCache(for: child.id)
        
        // Reload
        loadReport()
    }
    
    // MARK: - Child Selection
    
    /// Select a different child and reload the report
    func selectChild(_ child: Child) {
        guard child.id != selectedChild?.id else { return }
        
        selectedChild = child
        loadReport()
        
        #if DEBUG
        print("[ParentProgressDashboardViewModel] Switched to child: \(child.name)")
        #endif
    }
    
    // MARK: - Period Selection
    
    /// Change the report period and reload
    func changePeriod(_ period: ReportPeriod) {
        guard period != selectedPeriod else { return }
        
        selectedPeriod = period
        loadReport()
        
        #if DEBUG
        print("[ParentProgressDashboardViewModel] Changed period to: \(period.rawValue)")
        #endif
    }
    
    // MARK: - Export
    
    /// Export the current report to PDF
    func exportToPDF() {
        guard let report = currentReport else {
            exportError = "No report available to export"
            return
        }
        
        isExporting = true
        exportError = nil
        exportedPDFURL = nil
        
        #if DEBUG
        print("[ParentProgressDashboardViewModel] PDF export starting for \(report.childName)")
        #endif
        
        // Generate PDF on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Thread-safety: Ensure pdfService is still valid
            guard self.pdfService != nil else {
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportError = "PDF service is unavailable"
                }
                return
            }
            
            let result = self.pdfService.exportProgressReport(report)
            
            DispatchQueue.main.async {
                self.isExporting = false
                
                switch result {
                case .success(let url):
                    self.exportedPDFURL = url
                    self.showShareSheet = true
                    self.exportError = nil
                    #if DEBUG
                    print("[ParentProgressDashboardViewModel] PDF export successful: \(url.lastPathComponent)")
                    #endif
                    
                case .failure(let error):
                    self.exportError = error.localizedDescription
                    self.exportedPDFURL = nil
                    #if DEBUG
                    print("[ParentProgressDashboardViewModel] PDF export failed: \(error.localizedDescription)")
                    #endif
                }
            }
        }
    }
    
    /// Share the exported report
    func shareReport() {
        guard exportedPDFURL != nil else {
            exportError = "No report available to share"
            return
        }
        
        showShareSheet = true
    }
    
    /// Clear export state (call when share sheet is dismissed)
    func clearExportState() {
        // Keep the URL around for potential re-sharing
        showShareSheet = false
        exportError = nil
    }
    
    // MARK: - Helpers
    
    /// Format a date for display
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Get color for a trend
    func trendColor(_ trend: Trend) -> Color {
        switch trend {
        case .improving: return .success
        case .declining: return .warning
        case .stable: return .brandPrimary
        }
    }
    
    /// Get icon name for a category
    func categoryIcon(_ category: LessonCategory) -> String {
        category.iconName
    }
    
    /// Get color for a category
    func categoryColor(_ category: LessonCategory) -> Color {
        category.color
    }
    
    /// Format learning time for display
    func formatLearningTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else if mins > 0 {
            return "\(mins) minute\(mins == 1 ? "" : "s")"
        } else {
            return "0 minutes"
        }
    }
    
    /// Get a summary string for the report header
    var reportSummary: String {
        guard let report = currentReport else { return "" }
        
        if report.periodLessonsCompleted == 0 {
            return "No lessons completed \(selectedPeriod.rawValue.lowercased())"
        }
        
        return "\(report.periodLessonsCompleted) lesson\(report.periodLessonsCompleted == 1 ? "" : "s") • \(report.formattedLearningTime) of learning"
    }
    
    /// Check if a specific period is selected
    func isPeriodSelected(_ period: ReportPeriod) -> Bool {
        selectedPeriod == period
    }
    
    /// Get progress percentage for a category (0.0 to 1.0)
    func progressForCategory(_ category: LessonCategory) -> Double {
        guard let stats = currentReport?.categoryProgress.first(where: { $0.category == category }) else {
            return 0.0
        }
        return stats.completionPercentage
    }
}
