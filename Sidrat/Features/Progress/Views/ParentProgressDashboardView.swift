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
                        DashboardExportingOverlay()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: viewModel?.isExporting)
                    }
                }
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if let viewModel {
            if viewModel.isLoadingReport {
                DashboardLoadingState()
            } else if let errorMessage = viewModel.errorMessage {
                DashboardErrorState(message: errorMessage) {
                    Task {
                        viewModel.refreshReport()
                    }
                }
            } else if let report = viewModel.currentReport {
                if report.hasEnoughData {
                    reportContent(report: report)
                } else {
                    DashboardEmptyState {
                        dismiss()
                    }
                }
            } else {
                DashboardNoChildState()
            }
        } else {
            DashboardLoadingState()
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
                
                // Activity Chart (replaces Week Comparison)
                activityChartSection(report: report)
                
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
        // Weekly goal: configurable per child, defaults to 7
        let weeklyGoal = viewModel?.selectedChild?.weeklyLearningGoal ?? 7
        
        return StatsOverviewCard(
            totalXP: report.totalXP,
            currentStreak: report.currentStreak,
            totalLessons: report.totalLessonsCompleted,
            weeklyCompleted: report.periodLessonsCompleted,
            weeklyGoal: weeklyGoal
        )
    }
    
    // MARK: - Activity Chart Section
    
    private func activityChartSection(report: ProgressReport) -> some View {
        ActivityChartCard(
            dailyActivity: report.dailyActivity,
            periodLessons: report.periodLessonsCompleted
        )
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
    
    // MARK: - Setup
    
    private func setupViewModel() {
        if viewModel == nil {
            viewModel = ParentProgressDashboardViewModel(modelContext: modelContext)
            viewModel?.setup(children: children, currentChildId: appState.currentChildId)
        }
    }
}

// MARK: - Preview

#Preview {
    ParentProgressDashboardView()
        .modelContainer(for: [Child.self, Lesson.self, LessonProgress.self, Achievement.self, FamilyActivity.self])
        .environment(AppState())
}
