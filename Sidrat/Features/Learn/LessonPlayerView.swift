//
//  LessonPlayerView.swift
//  Sidrat
//
//  Interactive lesson player with Hook-Teach-Practice-Reward structure
//  Features 4-phase learning experience with visual progress indicator
//

import SwiftUI
import SwiftData

struct LessonPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let lesson: Lesson
    @Query private var children: [Child]
    
    // ViewModel initialization deferred until we have child
    @State private var viewModel: LessonPlayerViewModel?
    @State private var showingCompletion = false
    @State private var animateContent = false
    @State private var phaseTransitionOpacity: Double = 1.0
    @State private var headerVisible = true
    @State private var audioService = AudioNarrationService()
    @State private var audioPlayer = AudioPlayerService()
    @State private var showAudioControls = false
    @State private var showResumeBanner = false
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.surfacePrimary
                .ignoresSafeArea()
            
            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Resume banner (US-204)
                    if showResumeBanner, let resumePhase = vm.resumeFromPhase {
                        ResumeBanner(phaseName: resumePhase.title)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                    }
                    
                    // Header with phase indicator (hidden during reward)
                    if headerVisible {
                        phaseHeader(vm)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Phase content
                    phaseContent(vm)
                        .opacity(phaseTransitionOpacity)
                    
                    Spacer(minLength: 0)
                }
                
                // Floating audio controls overlay (when audio is loaded)
                if showAudioControls && audioPlayer.playbackState != .idle {
                    VStack {
                        Spacer()
                        
                        FloatingAudioControls(
                            audioPlayer: audioPlayer,
                            category: lesson.category,
                            onDismiss: {
                                withAnimation {
                                    showAudioControls = false
                                }
                            }
                        )
                        .padding(.trailing, Spacing.lg)
                        .padding(.bottom, Spacing.xl)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            } else {
                // Loading state
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            }
        }
        .navigationBarHidden(true)
        .task {
            // Check for partial progress on view appear (US-204)
            if let vm = viewModel {
                await vm.checkForPartialProgress()
                if vm.hasPartialProgress {
                    withAnimation {
                        showResumeBanner = true
                    }
                    // Auto-dismiss banner after 3 seconds
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        withAnimation {
                            showResumeBanner = false
                        }
                    }
                }
            }
        }
        .onAppear {
            setupViewModel()
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                animateContent = true
            }
        }
        .onDisappear {
            audioService.stop()
            audioPlayer.stop()
        }
        .confirmationDialog(
            "Exit Lesson?",
            isPresented: Binding(
                get: { viewModel?.showExitConfirmation ?? false },
                set: { viewModel?.showExitConfirmation = $0 }
            ),
            titleVisibility: .visible
        ) {
            Button("Exit", role: .destructive) {
                viewModel?.confirmExit()
                dismiss()
            }
            Button("Continue Learning", role: .cancel) {
                viewModel?.cancelExit()
            }
        } message: {
            Text("If you exit now, your progress will be saved and you can resume this lesson later.")
        }
        .fullScreenCover(isPresented: $showingCompletion) {
            if let vm = viewModel {
                LessonCompletionView(
                    lesson: lesson,
                    score: vm.score,
                    totalQuestions: vm.totalQuestions,
                    onDismiss: {
                        dismiss()
                    }
                )
            }
        }
        .onChange(of: viewModel?.isLessonComplete ?? false) { _, isComplete in
            if isComplete {
                showingCompletion = true
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupViewModel() {
        guard let child = currentChild else { return }
        let progressService = LessonProgressService(modelContext: modelContext)
        viewModel = LessonPlayerViewModel(
            lesson: lesson,
            child: child,
            modelContext: modelContext,
            progressService: progressService
        )
    }
    
    // MARK: - Phase Header
    
    private func phaseHeader(_ vm: LessonPlayerViewModel) -> some View {
        VStack(spacing: Spacing.md) {
            // Top bar with close and audio buttons
            HStack {
                // Close button
                Button {
                    vm.requestExit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.surfaceSecondary)
                        )
                }
                .accessibilityLabel("Exit lesson")
                .accessibilityHint("Double tap to exit this lesson")
                
                Spacer()
                
                // Audio toggle
                Button {
                    vm.isAudioEnabled.toggle()
                } label: {
                    Image(systemName: vm.isAudioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(vm.isAudioEnabled ? .brandPrimary : .textTertiary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.surfaceSecondary)
                        )
                }
                .accessibilityLabel(vm.isAudioEnabled ? "Mute audio" : "Enable audio")
            }
            
            // Phase indicator - 4 circles, 12pt diameter, 8pt spacing
            PhaseIndicator(
                currentPhase: vm.currentPhase,
                completedPhases: vm.completedPhases
            )
            
            // Lesson title with category
            HStack(spacing: Spacing.xs) {
                Image(systemName: lesson.category.iconName)
                    .font(.caption)
                    .foregroundStyle(lesson.category.color)
                
                Text(lesson.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .background(
            Color.surfacePrimary
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
        )
    }
    
    // MARK: - Phase Content
    
    @ViewBuilder
    private func phaseContent(_ vm: LessonPlayerViewModel) -> some View {
        switch vm.currentPhase {
        case .hook:
            hookPhaseView(vm)
            
        case .teach:
            teachPhaseView(vm)
            
        case .practice:
            practicePhaseView(vm)
            
        case .reward:
            rewardPhaseView(vm)
        }
    }
    
    // MARK: - Hook Phase (30-45 seconds)
    
    private func hookPhaseView(_ vm: LessonPlayerViewModel) -> some View {
        HookPhaseView(
            content: vm.hookContent ?? HookContent.forCategory(lesson.category),
            category: lesson.category,
            audioService: audioService,
            onComplete: {
                transitionToPhase(.teach, vm: vm)
            }
        )
    }
    
    // MARK: - Teach Phase (2-2.5 minutes)
    
    private func teachPhaseView(_ vm: LessonPlayerViewModel) -> some View {
        TeachPhaseView(
            contents: vm.teachContent,
            category: lesson.category,
            audioService: audioService,
            audioPlayer: audioPlayer,
            onComplete: {
                transitionToPhase(.practice, vm: vm)
            }
        )
    }
    
    // MARK: - Practice Phase (quiz/matching/sequencing)
    
    private func practicePhaseView(_ vm: LessonPlayerViewModel) -> some View {
        PracticePhaseView(
            practices: vm.practiceContent,
            category: lesson.category,
            audioService: audioService,
            onComplete: { correct, total in
                vm.correctAnswers = correct
                vm.totalQuestions = total
                transitionToPhase(.reward, vm: vm)
            }
        )
    }
    
    // MARK: - Reward Phase
    
    private func rewardPhaseView(_ vm: LessonPlayerViewModel) -> some View {
        RewardPhaseView(
            lesson: lesson,
            score: vm.score,
            correctCount: vm.correctAnswers,
            totalCount: vm.totalQuestions,
            xpEarned: vm.xpEarned,
            audioService: audioService,
            onShare: {
                vm.showShareSheet = true
            },
            onContinue: {
                vm.completeLesson()
            }
        )
        .onAppear {
            // Hide header during reward phase
            withAnimation(.easeInOut(duration: 0.3)) {
                headerVisible = false
            }
        }
    }
    
    // MARK: - Phase Transitions
    
    private func transitionToPhase(_ newPhase: LessonPlayerViewModel.Phase, vm: LessonPlayerViewModel) {
        // Stop current audio
        audioService.stop()
        audioPlayer.stop()
        
        // Apply transition animation
        if reduceMotion {
            vm.transitionToPhase(newPhase)
            loadAudioForPhase(newPhase)
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                phaseTransitionOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.transitionToPhase(newPhase)
                self.loadAudioForPhase(newPhase)
                
                withAnimation(.easeIn(duration: 0.3)) {
                    phaseTransitionOpacity = 1
                }
            }
        }
    }
    
    // MARK: - Audio Management
    
    /// Load appropriate audio for the current phase
    private func loadAudioForPhase(_ phase: LessonPlayerViewModel.Phase) {
        // Show/hide audio controls based on phase
        withAnimation(.spring(response: 0.4)) {
            showAudioControls = (phase == .hook || phase == .teach)
        }
        
        // Try to load bundled audio for this phase
        let audioFileName: String?
        
        switch phase {
        case .hook:
            audioFileName = "lesson_intro.mp3"
        case .teach:
            // Try lesson-specific audio first, fall back to generic
            audioFileName = "\(lesson.category.rawValue)_story.mp3"
        case .practice:
            audioFileName = nil // Practice uses sound effects only
        case .reward:
            audioFileName = nil // Reward uses celebratory sounds
        }
        
        if let fileName = audioFileName {
            if audioPlayer.loadAudio(named: fileName) {
                // Auto-play for hook phase
                if phase == .hook {
                    audioPlayer.play()
                }
            }
        }
        
        // Sync audio enabled state
        audioPlayer.isAudioEnabled = viewModel?.isAudioEnabled ?? true
    }
}

// MARK: - Legacy Lesson Step Model (kept for backwards compatibility)

struct LessonStep {
    enum StepType {
        case story
        case quiz
        case activity
        case summary
    }
    
    let type: StepType
    let title: String
    let content: String
    let icon: String?
    let funFact: String?
    let options: [String]
    let correctAnswer: Int?
    let activitySteps: [String]
    
    init(
        type: StepType,
        title: String,
        content: String = "",
        icon: String? = nil,
        funFact: String? = nil,
        options: [String] = [],
        correctAnswer: Int? = nil,
        activitySteps: [String] = []
    ) {
        self.type = type
        self.title = title
        self.content = content
        self.icon = icon
        self.funFact = funFact
        self.options = options
        self.correctAnswer = correctAnswer
        self.activitySteps = activitySteps
    }
}

// MARK: - Legacy Step Generator (kept for backwards compatibility)

func generateStepsForLesson(_ lesson: Lesson) -> [LessonStep] {
    // Returns minimal steps - actual content now comes from LessonContentGenerator
    return [
        LessonStep(
            type: .story,
            title: lesson.title,
            content: lesson.lessonDescription,
            icon: lesson.category.iconName
        )
    ]
}

// MARK: - Resume Banner

/// Banner displayed when resuming from partial progress (US-204)
struct ResumeBanner: View {
    let phaseName: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.brandPrimary)
            
            Text("Resuming from \(phaseName)")
                .font(.bodyMedium)
                .foregroundStyle(.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.brandPrimary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .strokeBorder(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
}

// MARK: - Preview

#Preview {
    LessonPlayerView(lesson: .sampleWuduLesson)
        .environment(AppState())
}
