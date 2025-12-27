//
//  LessonPlayerView.swift
//  Sidrat
//
//  Interactive lesson player with stories, quizzes, and activities
//

import SwiftUI
import SwiftData

struct LessonPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    let lesson: Lesson
    @Query private var children: [Child]
    
    @State private var currentStepIndex = 0
    @State private var score = 0
    @State private var showingCompletion = false
    @State private var selectedAnswer: Int? = nil
    @State private var isAnswerRevealed = false
    @State private var animateContent = false
    
    private var currentChild: Child? {
        guard let childId = appState.currentChildId,
              let uuid = UUID(uuidString: childId) else { return nil }
        return children.first { $0.id == uuid }
    }
    
    // Generate lesson steps based on the lesson
    private var lessonSteps: [LessonStep] {
        generateStepsForLesson(lesson)
    }
    
    private var currentStep: LessonStep {
        lessonSteps[currentStepIndex]
    }
    
    private var progress: Double {
        Double(currentStepIndex + 1) / Double(lessonSteps.count)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.backgroundSecondary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Content
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        stepContent
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                
                // Bottom action
                bottomAction
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                animateContent = true
            }
        }
        .fullScreenCover(isPresented: $showingCompletion) {
            LessonCompletionView(
                lesson: lesson,
                score: score,
                totalQuestions: lessonSteps.filter { $0.type == .quiz }.count,
                onDismiss: {
                    completeLesson()
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(Color.backgroundTertiary)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Step counter
                Text("Step \(currentStepIndex + 1) of \(lessonSteps.count)")
                    .font(.labelSmall)
                    .foregroundStyle(.textSecondary)
                
                Spacer()
                
                // Score
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.brandAccent)
                    Text("\(score)")
                        .font(.labelMedium)
                        .foregroundStyle(.textPrimary)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.brandAccent.opacity(0.1))
                .clipShape(Capsule())
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color.backgroundPrimary)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep.type {
        case .story:
            storyView
        case .quiz:
            quizView
        case .activity:
            activityView
        case .summary:
            summaryView
        }
    }
    
    // MARK: - Story View
    
    private var storyView: some View {
        VStack(spacing: Spacing.lg) {
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandPrimary.opacity(0.2), Color.brandSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: currentStep.icon ?? "book.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.brandPrimary)
                    .scaleEffect(animateContent ? 1 : 0.5)
                    .opacity(animateContent ? 1 : 0)
            }
            .padding(.top, Spacing.xl)
            
            // Title
            Text(currentStep.title)
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textPrimary)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            // Story text
            Text(currentStep.content)
                .font(.bodyLarge)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textSecondary)
                .lineSpacing(8)
                .padding(.horizontal)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            // Fun fact if available
            if let funFact = currentStep.funFact {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.brandAccent)
                    Text(funFact)
                        .font(.bodySmall)
                        .foregroundStyle(.textSecondary)
                }
                .padding()
                .background(Color.brandAccent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .opacity(animateContent ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Quiz View
    
    private var quizView: some View {
        VStack(spacing: Spacing.lg) {
            // Question icon
            ZStack {
                Circle()
                    .fill(Color.brandAccent.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "questionmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.brandAccent)
            }
            .padding(.top, Spacing.md)
            
            // Question
            Text(currentStep.title)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textPrimary)
            
            // Options
            VStack(spacing: Spacing.sm) {
                ForEach(Array(currentStep.options.enumerated()), id: \.offset) { index, option in
                    QuizOptionButton(
                        text: option,
                        isSelected: selectedAnswer == index,
                        isCorrect: index == currentStep.correctAnswer,
                        isRevealed: isAnswerRevealed
                    ) {
                        if !isAnswerRevealed {
                            selectedAnswer = index
                        }
                    }
                }
            }
            .padding(.top, Spacing.md)
            
            // Feedback
            if isAnswerRevealed {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: selectedAnswer == currentStep.correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(selectedAnswer == currentStep.correctAnswer ? .success : .error)
                    
                    Text(selectedAnswer == currentStep.correctAnswer ? "Great job! That's correct! 🎉" : "Not quite, but keep learning! 💪")
                        .font(.labelMedium)
                        .foregroundStyle(selectedAnswer == currentStep.correctAnswer ? .success : .error)
                }
                .padding()
                .background((selectedAnswer == currentStep.correctAnswer ? Color.success : Color.error).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Activity View
    
    private var activityView: some View {
        VStack(spacing: Spacing.lg) {
            // Activity icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandSecondary, Color.brandSecondary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.brandSecondary.opacity(0.3), radius: 12, y: 6)
                
                Image(systemName: currentStep.icon ?? "hands.sparkles.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .padding(.top, Spacing.md)
            
            Text(currentStep.title)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textPrimary)
            
            Text(currentStep.content)
                .font(.bodyMedium)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textSecondary)
                .lineSpacing(6)
            
            // Activity steps
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(Array(currentStep.activitySteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.brandPrimary)
                                .frame(width: 28, height: 28)
                            
                            Text("\(index + 1)")
                                .font(.labelSmall)
                                .foregroundStyle(.white)
                        }
                        
                        Text(step)
                            .font(.bodyMedium)
                            .foregroundStyle(.textPrimary)
                    }
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Summary View
    
    private var summaryView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.brandAccent)
            
            Text("Lesson Complete!")
                .font(.title2)
                .foregroundStyle(.textPrimary)
            
            Text(currentStep.content)
                .font(.bodyMedium)
                .multilineTextAlignment(.center)
                .foregroundStyle(.textSecondary)
            
            // Key takeaways
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Remember:")
                    .font(.labelMedium)
                    .foregroundStyle(.textPrimary)
                
                ForEach(currentStep.activitySteps, id: \.self) { point in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.brandSecondary)
                        
                        Text(point)
                            .font(.bodySmall)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .padding()
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .cardShadow()
    }
    
    // MARK: - Bottom Action
    
    private var bottomAction: some View {
        VStack(spacing: 0) {
            Divider()
            
            Group {
                if currentStep.type == .quiz && !isAnswerRevealed {
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            isAnswerRevealed = true
                            if selectedAnswer == currentStep.correctAnswer {
                                score += 10
                            }
                        }
                    } label: {
                        Text("Check Answer")
                            .font(.labelLarge)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md + 2)
                            .background(selectedAnswer != nil ? LinearGradient.primaryGradient : LinearGradient(colors: [Color.backgroundTertiary, Color.backgroundTertiary], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .disabled(selectedAnswer == nil)
                } else {
                    Button {
                        goToNextStep()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Text(currentStepIndex == lessonSteps.count - 1 ? "Finish Lesson" : "Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.labelLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md + 2)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, y: 4)
                    }
                }
            }
            .padding()
            .background(Color.backgroundPrimary)
        }
    }
    
    // MARK: - Actions
    
    private func goToNextStep() {
        if currentStepIndex < lessonSteps.count - 1 {
            animateContent = false
            withAnimation(.easeOut(duration: 0.2)) {
                currentStepIndex += 1
                selectedAnswer = nil
                isAnswerRevealed = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6)) {
                    animateContent = true
                }
            }
        } else {
            showingCompletion = true
        }
    }
    
    private func completeLesson() {
        guard let child = currentChild else { return }
        
        // Check if progress already exists
        if let existingProgress = child.lessonProgress.first(where: { $0.lessonId == lesson.id }) {
            existingProgress.attempts += 1
            existingProgress.score = max(existingProgress.score, score)
        } else {
            // Create new progress
            let progress = LessonProgress(
                lessonId: lesson.id,
                isCompleted: true,
                completedAt: Date(),
                score: score,
                xpEarned: lesson.xpReward,
                attempts: 1
            )
            progress.child = child
            child.lessonProgress.append(progress)
            
            // Update child stats
            child.totalLessonsCompleted += 1
            child.totalXP += lesson.xpReward
            
            // Update streak
            updateStreak(for: child)
        }
        
        // Check for achievements
        checkAchievements(for: child)
        
        do {
            try modelContext.save()
        } catch {
            print(" Error saving progress: \(error)")
        }
    }
    
    private func updateStreak(for child: Child) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = appState.lastCompletedDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let dayDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if dayDifference == 1 {
                // Consecutive day
                child.currentStreak += 1
                child.longestStreak = max(child.longestStreak, child.currentStreak)
            } else if dayDifference > 1 {
                // Streak broken
                child.currentStreak = 1
            }
            // Same day - no change
        } else {
            // First lesson ever
            child.currentStreak = 1
        }
        
        appState.lastCompletedDate = today
        appState.dailyStreak = child.currentStreak
    }
    
    private func checkAchievements(for child: Child) {
        let unlockedTypes = child.achievements.map { $0.achievementType }
        var newAchievements: [AchievementType] = []
        
        // First lesson
        if child.totalLessonsCompleted == 1 && !unlockedTypes.contains(.firstLesson) {
            newAchievements.append(.firstLesson)
        }
        
        // Streak achievements
        if child.currentStreak >= 3 && !unlockedTypes.contains(.streak3) {
            newAchievements.append(.streak3)
        }
        if child.currentStreak >= 7 && !unlockedTypes.contains(.streak7) {
            newAchievements.append(.streak7)
        }
        if child.currentStreak >= 30 && !unlockedTypes.contains(.streak30) {
            newAchievements.append(.streak30)
        }
        
        // XP achievements
        if child.totalXP >= 500 && !unlockedTypes.contains(.superLearner) {
            newAchievements.append(.superLearner)
        }
        
        // Category specific
        let wuduLessons = child.lessonProgress.filter { progress in
            // Check if this is a wudu lesson (simplified check)
            progress.isCompleted
        }
        if wuduLessons.count >= 5 && !unlockedTypes.contains(.wuduMaster) {
            newAchievements.append(.wuduMaster)
        }
        
        // Create new achievements
        for type in newAchievements {
            let achievement = Achievement(achievementType: type)
            achievement.child = child
            child.achievements.append(achievement)
        }
    }
}

// MARK: - Quiz Option Button

struct QuizOptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isRevealed: Bool
    let action: () -> Void
    
    private var backgroundColor: Color {
        if isRevealed {
            if isCorrect {
                return Color.success.opacity(0.2)
            } else if isSelected {
                return Color.error.opacity(0.2)
            }
        }
        return isSelected ? Color.brandPrimary.opacity(0.1) : Color.backgroundSecondary
    }
    
    private var borderColor: Color {
        if isRevealed {
            if isCorrect {
                return Color.success
            } else if isSelected {
                return Color.error
            }
        }
        return isSelected ? Color.brandPrimary : Color.clear
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.labelMedium)
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isRevealed {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : "circle"))
                        .foregroundStyle(isCorrect ? .success : (isSelected ? .error : .textTertiary))
                } else {
                    Circle()
                        .stroke(isSelected ? Color.brandPrimary : Color.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if isSelected {
                                Circle()
                                    .fill(Color.brandPrimary)
                                    .frame(width: 14, height: 14)
                            }
                        }
                }
            }
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isRevealed)
    }
}

// MARK: - Lesson Step Model

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

// MARK: - Step Generator

func generateStepsForLesson(_ lesson: Lesson) -> [LessonStep] {
    switch lesson.category {
    case .wudu:
        return generateWuduSteps(lesson)
    case .salah:
        return generateSalahSteps(lesson)
    case .quran:
        return generateQuranSteps(lesson)
    case .aqeedah:
        return generateAqeedahSteps(lesson)
    case .adab:
        return generateAdabSteps(lesson)
    case .duaa:
        return generateDuaaSteps(lesson)
    case .seerah:
        return generateSeerahSteps(lesson)
    case .stories:
        return generateStoriesSteps(lesson)
    }
}

func generateWuduSteps(_ lesson: Lesson) -> [LessonStep] {
    [
        LessonStep(
            type: .story,
            title: "What is Wudu?",
            content: "Before we pray to Allah, we make ourselves clean in a special way. This is called Wudu (وضوء). It's like getting ready to meet someone very important!",
            icon: "drop.fill",
            funFact: "The Prophet Muhammad ﷺ said that cleanliness is half of faith!"
        ),
        LessonStep(
            type: .story,
            title: "Why Do We Make Wudu?",
            content: "When we make wudu, we wash away the dust and dirt from our day. It helps us feel fresh, calm, and ready to talk to Allah in our prayers.",
            icon: "sparkles",
            funFact: "Making wudu can also wash away our small mistakes!"
        ),
        LessonStep(
            type: .quiz,
            title: "What is Wudu?",
            content: "",
            options: ["A type of food", "Special cleaning before prayer", "A game we play", "A kind of animal"],
            correctAnswer: 1
        ),
        LessonStep(
            type: .activity,
            title: "Let's Practice!",
            content: "With a grown-up, practice the beginning of wudu. Start with saying 'Bismillah' (In the name of Allah).",
            icon: "hands.sparkles.fill",
            activitySteps: [
                "Go to the sink with a grown-up",
                "Say 'Bismillah' out loud",
                "Wash your hands 3 times",
                "High five your grown-up when done!"
            ]
        ),
        LessonStep(
            type: .quiz,
            title: "Why do we make Wudu?",
            content: "",
            options: ["To play a game", "To get clean before eating", "To get ready to pray to Allah", "Because it's fun"],
            correctAnswer: 2
        ),
        LessonStep(
            type: .summary,
            title: "Great Job!",
            content: "You learned about Wudu - the special way Muslims clean themselves before prayer!",
            activitySteps: [
                "Wudu means to wash and clean",
                "We make wudu before praying",
                "We start by saying Bismillah",
                "Cleanliness is important in Islam"
            ]
        )
    ]
}

func generateSalahSteps(_ lesson: Lesson) -> [LessonStep] {
    [
        LessonStep(
            type: .story,
            title: "What is Salah?",
            content: "Salah is when we pray to Allah. It's our special time to talk to Him, thank Him, and ask for His help. Muslims pray 5 times every day!",
            icon: "person.fill",
            funFact: "Prayer is the first thing we'll be asked about on the Day of Judgment!"
        ),
        LessonStep(
            type: .story,
            title: "The Five Daily Prayers",
            content: "We pray Fajr (morning), Dhuhr (noon), Asr (afternoon), Maghrib (sunset), and Isha (night). Each prayer is a gift to connect with Allah!",
            icon: "sun.max.fill"
        ),
        LessonStep(
            type: .quiz,
            title: "How many times do Muslims pray each day?",
            content: "",
            options: ["3 times", "5 times", "7 times", "10 times"],
            correctAnswer: 1
        ),
        LessonStep(
            type: .summary,
            title: "Amazing!",
            content: "You learned about Salah - our daily prayers to Allah!",
            activitySteps: [
                "Muslims pray 5 times a day",
                "Prayer connects us to Allah",
                "Each prayer has a special time",
                "Prayer is a beautiful gift"
            ]
        )
    ]
}

func generateQuranSteps(_ lesson: Lesson) -> [LessonStep] {
    [
        LessonStep(
            type: .story,
            title: "Allah's Special Book",
            content: "The Quran is Allah's words sent down to Prophet Muhammad ﷺ. It's the most special book in the world and guides us to be good Muslims!",
            icon: "book.fill",
            funFact: "The Quran was revealed over 23 years!"
        ),
        LessonStep(
            type: .quiz,
            title: "What is the Quran?",
            content: "",
            options: ["A storybook", "Allah's words to guide us", "A school book", "A recipe book"],
            correctAnswer: 1
        ),
        LessonStep(
            type: .summary,
            title: "Wonderful!",
            content: "You learned about the Holy Quran - Allah's special book!",
            activitySteps: [
                "The Quran is Allah's words",
                "It guides us to be good",
                "We should read it with respect",
                "The Quran helps us learn"
            ]
        )
    ]
}

func generateAqeedahSteps(_ lesson: Lesson) -> [LessonStep] {
    [
        LessonStep(
            type: .story,
            title: "Believing in Allah",
            content: "Allah created everything - the sun, moon, stars, trees, animals, and you! He is the Most Kind and Most Merciful.",
            icon: "star.fill",
            funFact: "Allah has 99 beautiful names that tell us about Him!"
        ),
        LessonStep(
            type: .quiz,
            title: "Who created everything?",
            content: "",
            options: ["The sun", "Allah", "The moon", "The trees"],
            correctAnswer: 1
        ),
        LessonStep(
            type: .summary,
            title: "Excellent!",
            content: "You learned about our belief in Allah!",
            activitySteps: [
                "Allah created everything",
                "Allah is One",
                "Allah loves us",
                "We worship only Allah"
            ]
        )
    ]
}

func generateAdabSteps(_ lesson: Lesson) -> [LessonStep] {
    [
        LessonStep(
            type: .story,
            title: "Good Manners",
            content: "Islam teaches us to be kind, polite, and helpful. Saying 'please' and 'thank you', being gentle with others, and smiling are all part of good adab!",
            icon: "heart.fill",
            funFact: "The Prophet ﷺ said smiling at someone is charity!"
        ),
        LessonStep(
            type: .quiz,
            title: "What does good adab include?",
            content: "",
            options: ["Being mean", "Being kind and polite", "Being loud", "Ignoring others"],
            correctAnswer: 1
        ),
        LessonStep(
            type: .summary,
            title: "Wonderful!",
            content: "You learned about good manners in Islam!",
            activitySteps: [
                "Be kind to everyone",
                "Say please and thank you",
                "Smile at others",
                "Help those in need"
            ]
        )
    ]
}

func generateDuaaSteps(_ lesson: Lesson) -> [LessonStep] {
    [
        LessonStep(
            type: .story,
            title: "Talking to Allah",
            content: "Du'a means asking Allah for help or thanking Him. You can make du'a anytime, anywhere! Allah always listens to us.",
            icon: "hands.sparkles.fill",
            funFact: "The Prophet ﷺ said du'a is the weapon of a believer!"
        ),
        LessonStep(
            type: .quiz,
            title: "What is Du'a?",
            content: "",
            options: ["A song", "Asking and thanking Allah", "A game", "A type of food"],
            correctAnswer: 1
        ),
        LessonStep(
            type: .summary,
            title: "Beautiful!",
            content: "You learned about Du'a - talking to Allah!",
            activitySteps: [
                "Du'a is asking Allah",
                "We can make du'a anytime",
                "Allah always listens",
                "Du'a can be in any language"
            ]
        )
    ]
}

func generateSeerahSteps(_ lesson: Lesson) -> [LessonStep] {
    [
        LessonStep(
            type: .story,
            title: "Our Beloved Prophet ﷺ",
            content: "Prophet Muhammad ﷺ was the best person who ever lived. He was kind to everyone - children, animals, and even his enemies!",
            icon: "person.crop.circle.fill",
            funFact: "The Prophet ﷺ would play with children and make them laugh!"
        ),
        LessonStep(
            type: .quiz,
            title: "Who was Prophet Muhammad ﷺ?",
            content: "",
            options: ["A king", "The best person and Allah's messenger", "A teacher only", "A storyteller"],
            correctAnswer: 1
        ),
        LessonStep(
            type: .summary,
            title: "MashaAllah!",
            content: "You learned about our beloved Prophet Muhammad ﷺ!",
            activitySteps: [
                "He was the final messenger",
                "He was kind to everyone",
                "He taught us Islam",
                "We should follow his example"
            ]
        )
    ]
}

func generateStoriesSteps(_ lesson: Lesson) -> [LessonStep] {
    [
        LessonStep(
            type: .story,
            title: "Stories from the Quran",
            content: "The Quran has many amazing stories about prophets and their people. These stories teach us important lessons about faith and being good.",
            icon: "book.closed.fill",
            funFact: "There are 25 prophets mentioned by name in the Quran!"
        ),
        LessonStep(
            type: .quiz,
            title: "What can we learn from Quran stories?",
            content: "",
            options: ["Magic tricks", "Important lessons about faith", "How to cook", "Nothing special"],
            correctAnswer: 1
        ),
        LessonStep(
            type: .summary,
            title: "Amazing!",
            content: "You explored wonderful stories from the Quran!",
            activitySteps: [
                "Stories teach us lessons",
                "Prophets were role models",
                "Faith helps in hard times",
                "Allah always helps believers"
            ]
        )
    ]
}

#Preview {
    LessonPlayerView(lesson: .sampleWuduLesson)
        .environment(AppState())
}
