//
//  ParentProgressDashboardView.swift
//  Sidrat
//
//  Parent Progress Dashboard main view (US-304)
//  Comprehensive progress reports with parental gate integration
//

import SwiftUI
import SwiftData

struct ParentProgressDashboardView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    // MARK: - SwiftData Queries
    
    @Query(sort: \Child.lastAccessedAt, order: .reverse) private var children: [Child]
    
    // MARK: - State
    
    @State private var viewModel: ParentProgressDashboardViewModel?
    @State private var showingActivityDetail: FamilyActivity?
    @State private var showingCategoryDetail: CategoryStats?
    @State private var showingExportSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Progress Report")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.textTertiary)
                        }
                        .accessibilityLabel("Close progress report")
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                viewModel?.exportToPDF()
                            } label: {
                                Label("Export PDF", systemImage: "arrow.down.doc")
                            }
                            
                            Button {
                                Task {
                                    viewModel?.refreshReport()
                                }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundStyle(.brandPrimary)
                        }
                    }
                }
                .background(Color.backgroundSecondary)
                .onAppear {
                    setupViewModel()
                }
                .sheet(item: $showingActivityDetail) { activity in
                    FamilyActivityDetailView(activity: activity)
                }
                .sheet(item: $showingCategoryDetail) { stats in
                    CategoryDetailSheet(categoryStats: stats)
                }
                .sheet(isPresented: $showingExportSheet) {
                    if let pdfURL = viewModel?.exportedPDFURL {
                        ShareSheet(items: [pdfURL])
                            .presentationDetents([.medium, .large])
                            .onDisappear {
                                viewModel?.clearExportState()
                            }
                    }
                }
                .onChange(of: viewModel?.showShareSheet) { _, newValue in
                    if newValue == true {
                        showingExportSheet = true
                    }
                }
                .overlay {
                    if viewModel?.isExporting == true {
                        exportingOverlay
                    }
                }
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if let viewModel {
            if viewModel.isLoadingReport {
                loadingState
            } else if let errorMessage = viewModel.errorMessage {
                errorState(message: errorMessage)
            } else if let report = viewModel.currentReport {
                if report.hasEnoughData {
                    reportContent(report: report)
                } else {
                    emptyState
                }
            } else {
                noChildState
            }
        } else {
            loadingState
        }
    }
    
    // MARK: - Report Content
    
    private func reportContent(report: ProgressReport) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Child selector (if multiple children)
                if children.count > 1 {
                    childSelectorSection
                }
                
                // Period selector
                periodSelectorSection
                
                // Last updated
                lastUpdatedLabel(report: report)
                
                // Stats overview
                statsOverviewSection(report: report)
                
                // Week comparison
                weekComparisonSection(report: report)
                
                // Category progress
                categoryProgressSection(report: report)
                
                // Suggested activities
                if !report.suggestedActivities.isEmpty {
                    suggestedActivitiesSection(report: report)
                }
                
                // Recent achievements
                if !report.recentAchievements.isEmpty {
                    recentAchievementsSection(report: report)
                }
                
                // Export button
                exportButtonSection
                
                // Bottom padding
                Spacer()
                    .frame(height: Spacing.xl)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
        }
        .refreshable {
            viewModel?.refreshReport()
        }
    }
    
    // MARK: - Child Selector Section
    
    private var childSelectorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Viewing progress for")
                .font(.caption)
                .foregroundStyle(.textSecondary)
            
            Menu {
                ForEach(children) { child in
                    Button {
                        viewModel?.selectChild(child)
                    } label: {
                        HStack {
                            Text(child.name)
                            if viewModel?.selectedChild?.id == child.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let selectedChild = viewModel?.selectedChild {
                        AvatarView(avatar: selectedChild.avatar, size: 32)
                        
                        Text(selectedChild.name)
                            .font(.labelLarge)
                            .foregroundStyle(.textPrimary)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.backgroundPrimary)
                .clipShape(Capsule())
                .cardShadow()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Period Selector Section
    
    private var periodSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(ReportPeriod.allCases) { period in
                    periodButton(period)
                }
            }
            .padding(.horizontal, Spacing.xxs)
        }
    }
    
    private func periodButton(_ period: ReportPeriod) -> some View {
        let isSelected = viewModel?.selectedPeriod == period
        
        return Button {
            viewModel?.changePeriod(period)
        } label: {
            Text(period.rawValue)
                .font(.labelSmall)
                .foregroundStyle(isSelected ? .white : .textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.brandPrimary : Color.backgroundPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.separator, lineWidth: 1)
                )
        }
        .accessibilityLabel(period.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    // MARK: - Last Updated Label
    
    private func lastUpdatedLabel(report: ProgressReport) -> some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption2)
            
            Text("Updated \(report.reportDate.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
        }
        .foregroundStyle(.textTertiary)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // MARK: - Stats Overview Section
    
    private func statsOverviewSection(report: ProgressReport) -> some View {
        StatsOverviewCard(
            totalXP: report.totalXP,
            currentStreak: report.currentStreak,
            totalLessons: report.totalLessonsCompleted,
            weeklyCompleted: report.periodLessonsCompleted,
            weeklyGoal: 7 // TODO: Make configurable
        )
    }
    
    // MARK: - Week Comparison Section
    
    private func weekComparisonSection(report: ProgressReport) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "This Week vs Last", icon: "chart.bar")
            
            WeekComparisonCard(comparison: report.weekComparison)
        }
    }
    
    // MARK: - Category Progress Section
    
    private func categoryProgressSection(report: ProgressReport) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "Learning Categories", icon: "folder")
            
            ForEach(report.sortedCategoryProgress) { stats in
                CategoryProgressCard(categoryStats: stats) {
                    showingCategoryDetail = stats
                }
            }
        }
    }
    
    // MARK: - Suggested Activities Section
    
    private func suggestedActivitiesSection(report: ProgressReport) -> some View {
        ActivityRecommendationsSection(
            recommendations: report.suggestedActivities
        ) { activity in
            showingActivityDetail = activity
        }
    }
    
    // MARK: - Recent Achievements Section
    
    private func recentAchievementsSection(report: ProgressReport) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(title: "Recent Achievements", icon: "star.circle")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(report.recentAchievements, id: \.rawValue) { achievement in
                        achievementBadge(achievement)
                    }
                }
                .padding(.horizontal, Spacing.xxs)
            }
        }
    }
    
    private func achievementBadge(_ achievement: AchievementType) -> some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(LinearGradient.accentGradient)
                    .frame(width: 56, height: 56)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            
            Text(achievement.title)
                .font(.caption)
                .foregroundStyle(.textSecondary)
                .lineLimit(1)
                .frame(width: 70)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Achievement: \(achievement.title)")
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.brandPrimary)
            
            Text(title)
                .font(.labelLarge)
                .foregroundStyle(.textPrimary)
        }
        .padding(.horizontal, Spacing.xs)
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.brandPrimary)
            
            Text("Generating report...")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
            
            Spacer()
        }
    }
    
    // MARK: - Error State
    
    private func errorState(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.displayLarge)
                .foregroundStyle(.warning)
            
            Text("Oops!")
                .font(.title2)
                .foregroundStyle(.textPrimary)
            
            Text(message)
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            Button {
                Task {
                    viewModel?.refreshReport()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.labelMedium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandPrimary)
            
            Spacer()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.celebrationIcon)
                .foregroundStyle(.textTertiary)
            
            Text("No Learning Data Yet")
                .font(.title2)
                .foregroundStyle(.textPrimary)
            
            Text("Complete some lessons to see progress reports here!")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            Button {
                dismiss()
            } label: {
                Text("Start Learning")
                    .font(.labelMedium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandPrimary)
            
            Spacer()
        }
    }
    
    // MARK: - No Child State
    
    private var noChildState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.celebrationIcon)
                .foregroundStyle(.textTertiary)
            
            Text("No Child Profile")
                .font(.title2)
                .foregroundStyle(.textPrimary)
            
            Text("Create a child profile to track their learning progress.")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            Spacer()
        }
    }
    
    // MARK: - Export Button Section
    
    private var exportButtonSection: some View {
        VStack(spacing: Spacing.sm) {
            Divider()
                .padding(.vertical, Spacing.sm)
            
            Button {
                viewModel?.exportToPDF()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.title3)
                    
                    Text("Export Progress Report (PDF)")
                        .font(.labelLarge)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    LinearGradient(
                        colors: [Color.brandPrimary, Color.brandPrimaryLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .cardShadow()
            }
            .disabled(viewModel?.isExporting == true || viewModel?.currentReport == nil)
            .accessibilityLabel("Export progress report as PDF")
            .accessibilityHint("Generates a PDF document of your child's learning progress")
            
            // Export error message
            if let error = viewModel?.exportError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.error)
                    .multilineTextAlignment(.center)
            }
            
            Text("Share your child's progress with family or save for your records")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.md)
    }
    
    // MARK: - Exporting Overlay
    
    private var exportingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.white)
                
                Text("Generating PDF...")
                    .font(.labelMedium)
                    .foregroundStyle(.white)
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(Color.brandPrimary.opacity(0.9))
            )
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: viewModel?.isExporting)
    }
    
    // MARK: - Setup
    
    private func setupViewModel() {
        if viewModel == nil {
            viewModel = ParentProgressDashboardViewModel(modelContext: modelContext)
            viewModel?.setup(children: children, currentChildId: appState.currentChildId)
        }
    }
}

// MARK: - Category Detail Sheet

private struct CategoryDetailSheet: View {
    let categoryStats: CategoryStats
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Category header
                    categoryHeader
                    
                    // Progress summary
                    progressSummary
                    
                    // Recent lessons
                    if !categoryStats.recentLessons.isEmpty {
                        recentLessonsSection
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle(categoryStats.category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.brandPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var categoryHeader: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(categoryStats.category.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: categoryStats.category.iconName)
                    .font(.largeTitle)
                    .foregroundStyle(categoryStats.category.color)
            }
            
            Text(categoryStats.category.rawValue)
                .font(.title2)
                .foregroundStyle(.textPrimary)
        }
        .padding(.top, Spacing.md)
    }
    
    private var progressSummary: some View {
        VStack(spacing: Spacing.sm) {
            // Progress ring would go here
            Text(categoryStats.formattedPercentage)
                .font(.displayMedium)
                .foregroundStyle(.brandPrimary)
            
            Text("\(categoryStats.completedCount) of \(categoryStats.totalCount) lessons completed")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
            
            if categoryStats.remainingCount > 0 {
                Text("\(categoryStats.remainingCount) remaining")
                    .font(.bodySmall)
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    private var recentLessonsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Lessons")
                .font(.labelLarge)
                .foregroundStyle(.textPrimary)
            
            ForEach(categoryStats.recentLessons) { lesson in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lesson.title)
                            .font(.labelMedium)
                            .foregroundStyle(.textPrimary)
                        
                        Text(lesson.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.brandAccent)
                        
                        Text("+\(lesson.xpEarned)")
                            .font(.labelSmall)
                            .foregroundStyle(.textSecondary)
                    }
                }
                .padding(Spacing.sm)
                .background(Color.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            }
        }
    }
}

// MARK: - Make CategoryStats Identifiable for sheet

extension CategoryStats: Equatable {
    static func == (lhs: CategoryStats, rhs: CategoryStats) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview

#Preview {
    ParentProgressDashboardView()
        .modelContainer(for: [Child.self, Lesson.self, LessonProgress.self, Achievement.self, FamilyActivity.self])
        .environment(AppState())
}
