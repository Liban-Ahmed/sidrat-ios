//
//  LessonPhase.swift
//  Sidrat
//
//  Defines the 4 phases of an engaging lesson experience
//  Hook → Teach → Practice → Reward
//

import Foundation
import SwiftUI

// MARK: - Lesson Phase

/// The four phases of an engaging lesson experience
enum LessonPhase: Int, CaseIterable, Identifiable {
    case hook = 0
    case teach = 1
    case practice = 2
    case reward = 3
    
    var id: Int { rawValue }
    
    /// Display name for the phase
    var title: String {
        switch self {
        case .hook: return "Get Ready"
        case .teach: return "Learn"
        case .practice: return "Practice"
        case .reward: return "Complete"
        }
    }
    
    /// Icon for phase indicator
    var icon: String {
        switch self {
        case .hook: return "sparkles"
        case .teach: return "book.fill"
        case .practice: return "pencil.and.list.clipboard"
        case .reward: return "star.fill"
        }
    }
    
    /// Primary color for the phase
    var color: Color {
        switch self {
        case .hook: return .brandAccent
        case .teach: return .brandPrimary
        case .practice: return .brandSecondary
        case .reward: return .brandAccent
        }
    }
    
    /// Target duration for each phase (in seconds)
    var targetDuration: TimeInterval {
        switch self {
        case .hook: return 37.5 // 30-45 seconds, average 37.5
        case .teach: return 135 // 2-2.5 minutes, average 2:15
        case .practice: return 90 // ~1.5 minutes for practice
        case .reward: return 30 // 30 seconds for celebration
        }
    }
    
    /// Next phase in sequence
    var next: LessonPhase? {
        switch self {
        case .hook: return .teach
        case .teach: return .practice
        case .practice: return .reward
        case .reward: return nil
        }
    }
    
    /// Previous phase in sequence
    var previous: LessonPhase? {
        switch self {
        case .hook: return nil
        case .teach: return .hook
        case .practice: return .teach
        case .reward: return .practice
        }
    }
    
    /// Convert phase to storage string for LessonProgress
    var storageString: String {
        switch self {
        case .hook: return "hook"
        case .teach: return "teach"
        case .practice: return "practice"
        case .reward: return "reward"
        }
    }
    
    /// Create phase from storage string
    static func from(storageString: String) -> LessonPhase? {
        switch storageString {
        case "hook": return .hook
        case "teach": return .teach
        case "practice": return .practice
        case "reward": return .reward
        default: return nil
        }
    }
    }


// MARK: - Phase Progress

/// Tracks progress within a lesson
struct LessonPhaseProgress {
    var currentPhase: LessonPhase = .hook
    var hookCompleted: Bool = false
    var teachStepsCompleted: Int = 0
    var teachTotalSteps: Int = 3
    var practiceAttempts: Int = 0
    var practiceCorrect: Int = 0
    var practiceTotal: Int = 0
    var isFirstViewing: Bool = true
    var xpEarned: Int = 0
    var score: Int = 0
    
    /// Overall progress percentage (0.0 - 1.0)
    var overallProgress: Double {
        let phaseWeight = 1.0 / Double(LessonPhase.allCases.count)
        var progress = Double(currentPhase.rawValue) * phaseWeight
        
        // Add partial progress within current phase
        switch currentPhase {
        case .hook:
            progress += hookCompleted ? phaseWeight : 0
        case .teach:
            let teachProgress = teachTotalSteps > 0 ? Double(teachStepsCompleted) / Double(teachTotalSteps) : 0
            progress += teachProgress * phaseWeight
        case .practice:
            let practiceProgress = practiceTotal > 0 ? Double(practiceCorrect) / Double(practiceTotal) : 0
            progress += practiceProgress * phaseWeight
        case .reward:
            progress = 1.0
        }
        
        return min(progress, 1.0)
    }
    
    /// Whether the user can skip to next phase
    var canSkipPhase: Bool {
        !isFirstViewing
    }
}

// MARK: - Hook Content

/// Content for the Hook phase - attention grabber
struct HookContent {
    let question: String
    let animation: HookAnimation
    let duration: TimeInterval
    
    enum HookAnimation: String {
        case sparkle = "sparkles"
        case question = "questionmark.circle.fill"
        case star = "star.fill"
        case heart = "heart.fill"
        case book = "book.fill"
        case hands = "hands.sparkles.fill"
    }
    
    static func forCategory(_ category: LessonCategory) -> HookContent {
        switch category {
        case .wudu:
            return HookContent(
                question: "Did you know? Before we talk to Allah in prayer, we do something special to get clean! 🌟",
                animation: .sparkle,
                duration: 37.5
            )
        case .salah:
            return HookContent(
                question: "What if you could talk to the Creator of everything, 5 times a day? You can! 🤲",
                animation: .star,
                duration: 37.5
            )
        case .quran:
            return HookContent(
                question: "Imagine getting a special letter from Allah Himself! That's what the Quran is! 📖",
                animation: .book,
                duration: 37.5
            )
        case .aqeedah:
            return HookContent(
                question: "Who made the beautiful sky, the shining sun, and wonderful you? Let's find out! ✨",
                animation: .sparkle,
                duration: 37.5
            )
        case .adab:
            return HookContent(
                question: "Did you know that a simple smile is a gift you can give anyone? 😊",
                animation: .heart,
                duration: 37.5
            )
        case .duaa:
            return HookContent(
                question: "What if you had a direct line to talk to Allah anytime you want? You do! 🌙",
                animation: .hands,
                duration: 37.5
            )
        case .seerah:
            return HookContent(
                question: "Want to meet the kindest person who ever lived? Let's learn about him! 💚",
                animation: .heart,
                duration: 37.5
            )
        case .stories:
            return HookContent(
                question: "Ready for an amazing adventure with brave prophets and incredible miracles? 🌈",
                animation: .book,
                duration: 37.5
            )
        }
    }
}

// MARK: - Teach Content

/// Content for the Teach phase - main learning content
struct TeachContent: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let icon: String
    let funFact: String?
    let requiresTapToContinue: Bool
    
    /// Estimated reading/narration time in seconds
    var estimatedDuration: TimeInterval {
        // Assume ~150 words per minute for narration
        let wordCount = Double(text.split(separator: " ").count)
        return max(15, wordCount / 2.5) // At least 15 seconds per step
    }
}

// MARK: - Practice Content

/// Content for the Practice phase - interactive element
enum PracticeContent {
    case quiz(QuizPractice)
    case matching(MatchingPractice)
    case sequencing(SequencingPractice)
    
    var maxAttempts: Int { 3 }
}

struct QuizPractice {
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

struct MatchingPractice {
    let pairs: [(left: String, right: String)]
    let instruction: String
}

struct SequencingPractice {
    let items: [String]
    let correctOrder: [Int]
    let instruction: String
}

// MARK: - Reward Content

/// Content for the Reward phase
struct RewardContent {
    let celebrationMessage: String
    let xpEarned: Int
    let starsEarned: Int
    let shareMessage: String
    let achievements: [String]
    
    static func forLesson(_ lesson: Lesson, score: Int) -> RewardContent {
        let stars = score >= 80 ? 3 : (score >= 60 ? 2 : 1)
        
        return RewardContent(
            celebrationMessage: score >= 80 ? "Amazing job! You're a star learner! 🌟" :
                               score >= 60 ? "Great work! Keep it up! 💪" :
                               "Good effort! Practice makes perfect! 📚",
            xpEarned: lesson.xpReward,
            starsEarned: stars,
            shareMessage: "I just learned about \(lesson.title) on Sidrat! 🎉",
            achievements: []
        )
    }
}

// MARK: - Lesson Content Generator

/// Generates all phase content for a lesson
struct LessonContentGenerator {
    
    static func generateContent(for lesson: Lesson) -> LessonPhaseContent {
        LessonPhaseContent(
            hook: HookContent.forCategory(lesson.category),
            teach: generateTeachContent(for: lesson),
            practice: generatePracticeContent(for: lesson),
            reward: RewardContent.forLesson(lesson, score: 100)
        )
    }
    
    private static func generateTeachContent(for lesson: Lesson) -> [TeachContent] {
        switch lesson.category {
        case .wudu:
            return wuduTeachContent
        case .salah:
            return salahTeachContent
        case .quran:
            return quranTeachContent
        case .aqeedah:
            return aqeedahTeachContent
        case .adab:
            return adabTeachContent
        case .duaa:
            return duaaTeachContent
        case .seerah:
            return seerahTeachContent
        case .stories:
            return storiesTeachContent
        }
    }
    
    private static func generatePracticeContent(for lesson: Lesson) -> [PracticeContent] {
        switch lesson.category {
        case .wudu:
            return wuduPracticeContent
        case .salah:
            return salahPracticeContent
        case .quran:
            return quranPracticeContent
        case .aqeedah:
            return aqeedahPracticeContent
        case .adab:
            return adabPracticeContent
        case .duaa:
            return duaaPracticeContent
        case .seerah:
            return seerahPracticeContent
        case .stories:
            return storiesPracticeContent
        }
    }
    
    // MARK: - Wudu Content
    
    private static var wuduTeachContent: [TeachContent] {
        [
            TeachContent(
                title: "What is Wudu?",
                text: "Before we pray to Allah, we make ourselves clean in a special way called Wudu. It's like getting ready to meet someone very, very important - and Allah is the most important of all!",
                icon: "drop.fill",
                funFact: "The Prophet Muhammad ﷺ said cleanliness is half of faith!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Why We Make Wudu",
                text: "When we make wudu, we wash away the dust and dirt from our day. It helps us feel fresh, calm, and ready to talk to Allah. It also shows respect when we come to pray.",
                icon: "sparkles",
                funFact: "Making wudu can even wash away small mistakes we made!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Starting Wudu",
                text: "We always start wudu by saying 'Bismillah' - which means 'In the name of Allah'. This reminds us that we're doing this for Allah. Then we wash our hands three times!",
                icon: "hands.sparkles.fill",
                funFact: nil,
                requiresTapToContinue: false
            )
        ]
    }
    
    private static var wuduPracticeContent: [PracticeContent] {
        [
            .quiz(QuizPractice(
                question: "What do we say before starting wudu?",
                options: ["Alhamdulillah", "Bismillah", "SubhanAllah", "Allahu Akbar"],
                correctIndex: 1,
                explanation: "'Bismillah' means 'In the name of Allah' - we say it to start wudu!"
            )),
            .quiz(QuizPractice(
                question: "How many times do we wash our hands in wudu?",
                options: ["One time", "Two times", "Three times", "Four times"],
                correctIndex: 2,
                explanation: "We wash our hands THREE times in wudu!"
            ))
        ]
    }
    
    // MARK: - Salah Content
    
    private static var salahTeachContent: [TeachContent] {
        [
            TeachContent(
                title: "What is Salah?",
                text: "Salah is our special time to talk to Allah. It's like having a direct phone call to the Creator of everything! We thank Allah, ask for help, and feel close to Him.",
                icon: "person.fill",
                funFact: "Prayer is the first thing we'll be asked about on the Day of Judgment!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Five Daily Prayers",
                text: "Muslims pray 5 times every day: Fajr at dawn, Dhuhr at noon, Asr in the afternoon, Maghrib at sunset, and Isha at night. Each prayer is a gift from Allah!",
                icon: "sun.max.fill",
                funFact: "The 5 daily prayers were a gift given during the Prophet's journey to the heavens!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Facing the Qiblah",
                text: "When we pray, we all face the same direction - toward the Ka'bah in Makkah. This helps us feel united with Muslims all around the world!",
                icon: "location.fill",
                funFact: nil,
                requiresTapToContinue: false
            )
        ]
    }
    
    private static var salahPracticeContent: [PracticeContent] {
        [
            .quiz(QuizPractice(
                question: "How many times do Muslims pray each day?",
                options: ["3 times", "5 times", "7 times", "2 times"],
                correctIndex: 1,
                explanation: "Muslims pray FIVE times each day!"
            )),
            .quiz(QuizPractice(
                question: "What direction do we face when praying?",
                options: ["East", "Toward the Ka'bah", "North", "Any direction"],
                correctIndex: 1,
                explanation: "We face the Ka'bah in Makkah when we pray!"
            ))
        ]
    }
    
    // MARK: - Quran Content
    
    private static var quranTeachContent: [TeachContent] {
        [
            TeachContent(
                title: "Allah's Special Book",
                text: "The Quran is the most special book in the whole world! It contains Allah's actual words, sent to guide us. It teaches us how to be good Muslims and live happy lives.",
                icon: "book.fill",
                funFact: "The Quran was revealed to Prophet Muhammad ﷺ over 23 years!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Respecting the Quran",
                text: "We treat the Quran with great respect. We keep it in a clean, high place. We make wudu before reading it. And we listen quietly when someone recites it.",
                icon: "heart.fill",
                funFact: "There are over 6,000 verses in the Quran!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Learning the Quran",
                text: "Many Muslims memorize the whole Quran! They are called Hafiz. But even learning a little bit of Quran brings great reward from Allah.",
                icon: "star.fill",
                funFact: nil,
                requiresTapToContinue: false
            )
        ]
    }
    
    private static var quranPracticeContent: [PracticeContent] {
        [
            .quiz(QuizPractice(
                question: "What is the Quran?",
                options: ["A storybook", "Allah's words to guide us", "A textbook", "A poetry book"],
                correctIndex: 1,
                explanation: "The Quran contains Allah's words sent to guide us!"
            ))
        ]
    }
    
    // MARK: - Aqeedah Content
    
    private static var aqeedahTeachContent: [TeachContent] {
        [
            TeachContent(
                title: "Allah Created Everything",
                text: "Look around you - the sky, the trees, the animals, the stars! Allah created all of it. He is the Most Powerful and Most Wise. Nothing is too big or too small for Allah!",
                icon: "star.fill",
                funFact: "Allah has 99 beautiful names that describe Him!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Allah is One",
                text: "There is only one God, and that is Allah. We worship Him alone. He has no partners, no parents, and no children. Allah is unique and special!",
                icon: "1.circle.fill",
                funFact: "The first pillar of Islam is believing in One God - Allah!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Allah Loves Us",
                text: "Allah loves us more than anyone! He gives us air to breathe, food to eat, and families who care for us. We show our love back by worshipping Him and being good.",
                icon: "heart.fill",
                funFact: nil,
                requiresTapToContinue: false
            )
        ]
    }
    
    private static var aqeedahPracticeContent: [PracticeContent] {
        [
            .quiz(QuizPractice(
                question: "Who created everything?",
                options: ["The sun", "Allah", "The moon", "Nature"],
                correctIndex: 1,
                explanation: "Allah created everything in the universe!"
            ))
        ]
    }
    
    // MARK: - Adab Content
    
    private static var adabTeachContent: [TeachContent] {
        [
            TeachContent(
                title: "Being Kind",
                text: "Islam teaches us to be kind to everyone - our family, friends, neighbors, and even animals! A kind word or a smile can make someone's whole day better.",
                icon: "heart.fill",
                funFact: "The Prophet ﷺ said smiling at someone is charity!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Good Manners",
                text: "Saying 'please' and 'thank you', sharing with others, being patient, and not interrupting - these are all part of good adab (manners) that Muslims should have.",
                icon: "hand.thumbsup.fill",
                funFact: "The Prophet ﷺ was known for having the best manners of anyone!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Respecting Others",
                text: "We respect our parents, teachers, elders, and everyone around us. We speak nicely, listen carefully, and help when we can. This makes Allah happy!",
                icon: "person.2.fill",
                funFact: nil,
                requiresTapToContinue: false
            )
        ]
    }
    
    private static var adabPracticeContent: [PracticeContent] {
        [
            .quiz(QuizPractice(
                question: "What does good adab include?",
                options: ["Being mean", "Being kind and polite", "Being loud", "Ignoring others"],
                correctIndex: 1,
                explanation: "Good adab means being kind, polite, and respectful!"
            ))
        ]
    }
    
    // MARK: - Du'a Content
    
    private static var duaaTeachContent: [TeachContent] {
        [
            TeachContent(
                title: "What is Du'a?",
                text: "Du'a means talking to Allah! You can ask Allah for anything - help with a problem, thanking Him for blessings, or just telling Him how you feel. Allah always listens!",
                icon: "hands.sparkles.fill",
                funFact: "The Prophet ﷺ said du'a is the weapon of a believer!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Anytime, Anywhere",
                text: "You can make du'a anytime - before eating, before sleeping, when you're happy or sad. You can make du'a in any language because Allah understands everything!",
                icon: "clock.fill",
                funFact: "Some special times for du'a: after prayer, while fasting, and when it rains!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Allah Answers",
                text: "Allah always answers our du'a! Sometimes He gives us what we asked for, sometimes He gives us something better, and sometimes He saves the reward for later.",
                icon: "checkmark.circle.fill",
                funFact: nil,
                requiresTapToContinue: false
            )
        ]
    }
    
    private static var duaaPracticeContent: [PracticeContent] {
        [
            .quiz(QuizPractice(
                question: "When can you make du'a?",
                options: ["Only at the mosque", "Only in Arabic", "Anytime, anywhere", "Only when sad"],
                correctIndex: 2,
                explanation: "You can make du'a anytime and anywhere!"
            ))
        ]
    }
    
    // MARK: - Seerah Content
    
    private static var seerahTeachContent: [TeachContent] {
        [
            TeachContent(
                title: "The Best Person",
                text: "Prophet Muhammad ﷺ was the best person who ever lived. He was kind, honest, patient, and brave. Allah chose him to bring Islam to the world!",
                icon: "person.crop.circle.fill",
                funFact: "The Prophet ﷺ was known as 'The Truthful One' even before he became a prophet!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Kind to Everyone",
                text: "The Prophet ﷺ was kind to children, animals, the poor, and even his enemies. He would smile, help others, and never turn anyone away who needed help.",
                icon: "heart.fill",
                funFact: "He would race with children and let them win!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Following His Example",
                text: "We love the Prophet ﷺ and try to be like him. We follow his teachings, called the Sunnah. When we do what he did, we get closer to Allah!",
                icon: "star.fill",
                funFact: nil,
                requiresTapToContinue: false
            )
        ]
    }
    
    private static var seerahPracticeContent: [PracticeContent] {
        [
            .quiz(QuizPractice(
                question: "How was the Prophet ﷺ known?",
                options: ["The Wealthy One", "The Truthful One", "The Strong One", "The Tall One"],
                correctIndex: 1,
                explanation: "He was called 'The Truthful One' because he always spoke the truth!"
            ))
        ]
    }
    
    // MARK: - Stories Content
    
    private static var storiesTeachContent: [TeachContent] {
        [
            TeachContent(
                title: "Amazing Stories",
                text: "The Quran has wonderful stories about prophets and their people. These stories teach us about faith, patience, and trusting Allah, even when things are hard.",
                icon: "book.closed.fill",
                funFact: "There are 25 prophets mentioned by name in the Quran!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Prophets Were Brave",
                text: "The prophets faced many challenges but they never gave up. Prophet Nuh built an ark, Prophet Ibrahim was thrown into fire, Prophet Musa faced a king - but Allah always helped them!",
                icon: "shield.fill",
                funFact: "The fire became cool and peaceful for Prophet Ibrahim!",
                requiresTapToContinue: true
            ),
            TeachContent(
                title: "Learning from Stories",
                text: "When we read these stories, we learn that Allah always helps those who trust Him. No matter what problems we have, if we pray and have patience, Allah will help us too!",
                icon: "lightbulb.fill",
                funFact: nil,
                requiresTapToContinue: false
            )
        ]
    }
    
    private static var storiesPracticeContent: [PracticeContent] {
        [
            .quiz(QuizPractice(
                question: "What can we learn from Quran stories?",
                options: ["Magic tricks", "Trust in Allah", "How to cook", "Nothing special"],
                correctIndex: 1,
                explanation: "Quran stories teach us to trust Allah and have patience!"
            ))
        ]
    }
}

// MARK: - Lesson Phase Content

/// All content for a lesson's phases
struct LessonPhaseContent {
    let hook: HookContent
    let teach: [TeachContent]
    let practice: [PracticeContent]
    let reward: RewardContent
}
