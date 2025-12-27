//
//  Child.swift
//  Sidrat
//
//  Child profile data model with COPPA-compliant design
//

import Foundation
import SwiftData

@Model
final class Child {
    // MARK: - Identity
    
    /// Unique identifier for the child
    var id: UUID = UUID()
    
    /// Display name (not required to be real name for privacy)
    var name: String = ""
    
    /// Birth year instead of exact birthdate for privacy (COPPA compliance)
    /// Store year only to calculate age without exposing exact date
    var birthYear: Int = 2019
    
    /// Avatar identifier matching AvatarOption enum
    /// Stored as String rawValue for SwiftData compatibility
    var avatarId: String = "cat"
    
    /// Profile creation timestamp
    var createdAt: Date = Date()
    
    /// Last time the profile was accessed
    var lastAccessedAt: Date = Date()
    
    // MARK: - Progress Tracking
    
    /// Current consecutive days streak
    var currentStreak: Int = 0
    
    /// Longest streak achieved
    var longestStreak: Int = 0
    
    /// Total number of lessons completed
    var totalLessonsCompleted: Int = 0
    
    /// Total experience points earned
    var totalXP: Int = 0
    
    /// Last date a lesson was completed (for streak calculation)
    var lastLessonCompletedDate: Date?
    
    /// Current week number in curriculum
    var currentWeekNumber: Int = 1
    
    // MARK: - Relationships
    
    /// Lesson progress history
    @Relationship(deleteRule: .cascade)
    var lessonProgress: [LessonProgress] = []
    
    /// Earned achievements
    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement] = []
    
    // MARK: - Computed Properties
    
    /// Current age calculated from birth year
    /// Returns age based on current calendar year
    @Transient
    var currentAge: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birthYear
    }
    
    /// Avatar option enum from stored ID
    @Transient
    var avatar: AvatarOption {
        AvatarOption(rawValue: avatarId) ?? .cat
    }
    
    /// Formatted age string for display
    @Transient
    var ageDescription: String {
        let age = currentAge
        return age == 1 ? "1 year old" : "\(age) years old"
    }
    
    /// Whether the profile was accessed today
    @Transient
    var wasAccessedToday: Bool {
        Calendar.current.isDateInToday(lastAccessedAt)
    }
    
    /// Days since last lesson completion
    @Transient
    var daysSinceLastLesson: Int? {
        guard let lastDate = lastLessonCompletedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }
    
    // MARK: - Initialization
    
    /// Initialize a new child profile
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated)
    ///   - name: Display name
    ///   - birthYear: Year of birth (e.g., 2019)
    ///   - avatarId: Avatar identifier matching AvatarOption rawValue
    ///   - currentStreak: Starting streak (default 0)
    ///   - longestStreak: Longest streak (default 0)
    ///   - totalLessonsCompleted: Lessons completed (default 0)
    ///   - totalXP: Experience points (default 0)
    ///   - currentWeekNumber: Starting week (default 1)
    init(
        id: UUID = UUID(),
        name: String,
        birthYear: Int,
        avatarId: String = AvatarOption.cat.rawValue,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalLessonsCompleted: Int = 0,
        totalXP: Int = 0,
        currentWeekNumber: Int = 1
    ) {
        self.id = id
        self.name = name
        self.birthYear = birthYear
        self.avatarId = avatarId
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalLessonsCompleted = totalLessonsCompleted
        self.totalXP = totalXP
        self.lastLessonCompletedDate = nil
        self.currentWeekNumber = currentWeekNumber
        self.lessonProgress = []
        self.achievements = []
    }
    
    // MARK: - Convenience Initializer (Legacy Support)
    
    /// Convenience initializer supporting legacy age parameter
    /// Converts age to birth year automatically
    /// - Parameters:
    ///   - name: Display name
    ///   - age: Current age (will be converted to birth year)
    ///   - avatarId: Avatar identifier
    convenience init(
        name: String,
        age: Int,
        avatarId: String = AvatarOption.cat.rawValue
    ) {
        let currentYear = Calendar.current.component(.year, from: Date())
        let birthYear = currentYear - age
        
        self.init(
            name: name,
            birthYear: birthYear,
            avatarId: avatarId
        )
    }
}

// MARK: - Child Profile Methods

extension Child {
    /// Update last accessed timestamp
    func markAsAccessed() {
        self.lastAccessedAt = Date()
    }
    
    /// Record a lesson completion and update progress
    /// - Parameters:
    ///   - xpEarned: Experience points earned from the lesson
    ///   - updateStreak: Whether to update the streak (default true)
    func recordLessonCompletion(xpEarned: Int, updateStreak: Bool = true) {
        // Update totals
        totalLessonsCompleted += 1
        totalXP += xpEarned
        
        // Update streak if needed
        if updateStreak {
            updateStreakForToday()
        }
        
        // Update last completed date
        lastLessonCompletedDate = Date()
    }
    
    /// Update streak based on today's completion
    private func updateStreakForToday() {
        let calendar = Calendar.current
        
        // Check if already completed today
        if let lastDate = lastLessonCompletedDate,
           calendar.isDate(lastDate, inSameDayAs: Date()) {
            return // Already counted today
        }
        
        // Check if streak should continue
        if let lastDate = lastLessonCompletedDate {
            let daysSince = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            
            if daysSince == 1 {
                // Continue streak
                currentStreak += 1
            } else if daysSince > 1 {
                // Streak broken, start new
                currentStreak = 1
            }
        } else {
            // First lesson ever
            currentStreak = 1
        }
        
        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }
    
    /// Check and reset streak if needed
    func checkStreakValidity() {
        guard let lastDate = lastLessonCompletedDate else { return }
        
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        
        // If more than 1 day has passed, reset current streak
        if daysSince > 1 {
            currentStreak = 0
        }
    }
    
    /// Progress percentage through current week's lessons
    /// Assumes 5 lessons per week
    func weekProgressPercentage() -> Double {
        let lessonsThisWeek = lessonProgress.filter { progress in
            guard let completedDate = progress.completedAt else { return false }
            return Calendar.current.isDate(completedDate, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
        
        return min(Double(lessonsThisWeek) / 5.0, 1.0)
    }
}

// MARK: - Identifiable Conformance

extension Child: Identifiable {}

// MARK: - Sample Data

extension Child {
    /// Sample child for previews and testing
    static let sample = Child(
        name: "Yusuf",
        birthYear: 2018, // Age 7 in 2025
        avatarId: AvatarOption.lion.rawValue,
        currentStreak: 5,
        longestStreak: 12,
        totalLessonsCompleted: 24,
        totalXP: 480,
        currentWeekNumber: 1
    )
    
    /// Sample child 2 for multi-profile testing
    static let sample2 = Child(
        name: "Aisha",
        birthYear: 2019, // Age 6 in 2025
        avatarId: AvatarOption.butterfly.rawValue,
        currentStreak: 3,
        longestStreak: 8,
        totalLessonsCompleted: 15,
        totalXP: 300,
        currentWeekNumber: 1
    )
    
    /// Array of sample children for testing
    static let samples = [sample, sample2]
}
// MARK: - Validation

extension Child {
    /// Validate child data meets requirements
    /// - Returns: Array of validation errors (empty if valid)
    func validate() -> [String] {
        var errors: [String] = []
        
        // Name validation
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Name cannot be empty")
        }
        
        if name.count > 50 {
            errors.append("Name must be 50 characters or less")
        }
        
        // Birth year validation
        let currentYear = Calendar.current.component(.year, from: Date())
        if birthYear < 1900 || birthYear > currentYear {
            errors.append("Birth year must be between 1900 and \(currentYear)")
        }
        
        let age = currentAge
        if age < 0 || age > 120 {
            errors.append("Age must be between 0 and 120")
        }
        
        // Avatar validation
        if AvatarOption(rawValue: avatarId) == nil {
            errors.append("Invalid avatar selection")
        }
        
        // Progress validation
        if currentStreak < 0 {
            errors.append("Current streak cannot be negative")
        }
        
        if longestStreak < currentStreak {
            errors.append("Longest streak cannot be less than current streak")
        }
        
        if totalLessonsCompleted < 0 {
            errors.append("Total lessons completed cannot be negative")
        }
        
        if totalXP < 0 {
            errors.append("Total XP cannot be negative")
        }
        
        return errors
    }
    
    /// Whether the child profile data is valid
    var isValid: Bool {
        validate().isEmpty
    }
}

