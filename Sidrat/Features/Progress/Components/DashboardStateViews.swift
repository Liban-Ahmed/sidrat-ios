//
//  DashboardStateViews.swift
//  Sidrat
//
//  Extracted state views for ParentProgressDashboardView
//  Loading, Error, Empty, and No Child states
//

import SwiftUI

// MARK: - Loading State

struct DashboardLoadingState: View {
    var body: some View {
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
}

// MARK: - Error State

struct DashboardErrorState: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
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
                onRetry()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.labelMedium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Empty State

struct DashboardEmptyState: View {
    let onStartLearning: () -> Void
    
    var body: some View {
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
                onStartLearning()
            } label: {
                Text("Start Learning")
                    .font(.labelMedium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandPrimary)
            
            Spacer()
        }
    }
}

// MARK: - No Child State

struct DashboardNoChildState: View {
    var body: some View {
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
}

// MARK: - Exporting Overlay

struct DashboardExportingOverlay: View {
    var body: some View {
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
    }
}

// MARK: - Previews

#Preview("Loading State") {
    DashboardLoadingState()
}

#Preview("Error State") {
    DashboardErrorState(message: "Failed to load report") {
        print("Retry tapped")
    }
}

#Preview("Empty State") {
    DashboardEmptyState {
        print("Start learning tapped")
    }
}

#Preview("No Child State") {
    DashboardNoChildState()
}

#Preview("Exporting Overlay") {
    ZStack {
        Color.gray.opacity(0.2)
        DashboardExportingOverlay()
    }
}
