//
//  Lesson.swift
//  Sidrat
//
//  Lesson data model
//

import Foundation
import SwiftData

@Model
final class Lesson: Identifiable {
    var id: UUID
    var title: String
    var lessonDescription: String
    var category: LessonCategory
    var difficulty: Difficulty
    var durationMinutes: Int
    var xpReward: Int
    var order: Int
    var weekNumber: Int
    
    // Content
    var content: [LessonContent]
    
    init(
        id: UUID = UUID(),
        title: String,
        lessonDescription: String,
        category: LessonCategory,
        difficulty: Difficulty = .beginner,
        durationMinutes: Int = 5,
        xpReward: Int = 20,
        order: Int,
        weekNumber: Int,
        content: [LessonContent] = []
    ) {
        self.id = id
        self.title = title
        self.lessonDescription = lessonDescription
        self.category = category
        self.difficulty = difficulty
        self.durationMinutes = durationMinutes
        self.xpReward = xpReward
        self.order = order
        self.weekNumber = weekNumber
        self.content = content
    }
}

// MARK: - Lesson Category

enum LessonCategory: String, Codable, CaseIterable {
    case aqeedah = "Aqeedah"
    case salah = "Salah"
    case wudu = "Wudu"
    case quran = "Quran"
    case seerah = "Seerah"
    case adab = "Adab"
    case duaa = "Du'a"
    case stories = "Stories"
    
    var icon: String {
        switch self {
        case .aqeedah: return "star.fill"
        case .salah: return "person.fill"
        case .wudu: return "drop.fill"
        case .quran: return "book.fill"
        case .seerah: return "person.crop.circle.fill"
        case .adab: return "heart.fill"
        case .duaa: return "hands.sparkles.fill"
        case .stories: return "book.closed.fill"
        }
    }
    
    var color: String {
        switch self {
        case .aqeedah: return "primaryGreen"
        case .salah: return "secondaryGold"
        case .wudu: return "accentBlue"
        case .quran: return "primaryGreen"
        case .seerah: return "secondaryGold"
        case .adab: return "error"
        case .duaa: return "accentBlue"
        case .stories: return "primaryGreen"
        }
    }
}

// MARK: - Difficulty

enum Difficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

// MARK: - Lesson Content

struct LessonContent: Codable, Identifiable {
    var id: UUID
    var type: ContentType
    var title: String?
    var text: String?
    var audioURL: String?
    var imageURL: String?
    var question: String?
    var options: [String]?
    var correctAnswer: Int?
    
    enum ContentType: String, Codable {
        case story
        case quiz
        case matching
        case audio
        case video
        case interactive
    }
    
    init(
        id: UUID = UUID(),
        type: ContentType,
        title: String? = nil,
        text: String? = nil,
        audioURL: String? = nil,
        imageURL: String? = nil,
        question: String? = nil,
        options: [String]? = nil,
        correctAnswer: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.text = text
        self.audioURL = audioURL
        self.imageURL = imageURL
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
    }
}

// MARK: - Sample Data

extension Lesson {
    static let sampleWuduLesson = Lesson(
        title: "What is Wudu?",
        lessonDescription: "Learn about the special way Muslims clean themselves before prayer",
        category: .wudu,
        difficulty: .beginner,
        durationMinutes: 5,
        xpReward: 20,
        order: 1,
        weekNumber: 1,
        content: [
            LessonContent(
                type: .story,
                title: "Why We Make Wudu",
                text: "Before we pray to Allah, we make ourselves clean. This special cleaning is called Wudu!"
            ),
            LessonContent(
                type: .quiz,
                question: "What is Wudu?",
                options: ["A type of food", "Special cleaning before prayer", "A game", "A song"],
                correctAnswer: 1
            )
        ]
    )
    
    // MARK: - Test Data Generator
    
    static func generateTestLessons() -> [Lesson] {
        return [
            // Week 1 - Wudu
            Lesson(
                title: "What is Wudu?",
                lessonDescription: "Learn about the special way Muslims clean themselves before prayer",
                category: .wudu,
                durationMinutes: 5,
                xpReward: 20,
                order: 1,
                weekNumber: 1,
                content: [
                    LessonContent(type: .story, title: "Why We Make Wudu", text: "Before we pray to Allah, we make ourselves clean. This special cleaning is called Wudu!"),
                    LessonContent(type: .quiz, question: "What is Wudu?", options: ["A type of food", "Special cleaning before prayer", "A game", "A song"], correctAnswer: 1)
                ]
            ),
            Lesson(
                title: "Why We Make Wudu",
                lessonDescription: "Discover why cleanliness is important in Islam",
                category: .wudu,
                durationMinutes: 5,
                xpReward: 20,
                order: 2,
                weekNumber: 1,
                content: [
                    LessonContent(type: .story, title: "Cleanliness in Islam", text: "Islam teaches us to be clean. When we make wudu, we wash away the dust and feel fresh and ready to talk to Allah!"),
                    LessonContent(type: .quiz, question: "Why is cleanliness important in Islam?", options: ["It isn't important", "To look nice", "Because Allah loves cleanliness", "For fun"], correctAnswer: 2)
                ]
            ),
            Lesson(
                title: "Steps of Wudu - Part 1",
                lessonDescription: "Learn the first steps of making wudu",
                category: .wudu,
                durationMinutes: 6,
                xpReward: 25,
                order: 3,
                weekNumber: 1,
                content: [
                    LessonContent(type: .story, title: "Starting Wudu", text: "We start wudu by saying Bismillah and washing our hands three times."),
                    LessonContent(type: .quiz, question: "What do we say before starting wudu?", options: ["Alhamdulillah", "Bismillah", "SubhanAllah", "Allahu Akbar"], correctAnswer: 1)
                ]
            ),
            Lesson(
                title: "Steps of Wudu - Part 2",
                lessonDescription: "Complete learning all the steps of wudu",
                category: .wudu,
                durationMinutes: 6,
                xpReward: 25,
                order: 4,
                weekNumber: 1,
                content: [
                    LessonContent(type: .story, title: "Completing Wudu", text: "After washing our face and arms, we wipe our head and wash our feet. Now we're ready to pray!"),
                    LessonContent(type: .quiz, question: "What's the last body part we wash in wudu?", options: ["Face", "Hands", "Feet", "Head"], correctAnswer: 2)
                ]
            ),
            Lesson(
                title: "The Wudu Du'a",
                lessonDescription: "Learn the beautiful prayer we say after wudu",
                category: .wudu,
                durationMinutes: 4,
                xpReward: 15,
                order: 5,
                weekNumber: 1,
                content: [
                    LessonContent(type: .story, title: "Du'a After Wudu", text: "After finishing wudu, we raise our finger and say a special du'a that Prophet Muhammad ﷺ taught us."),
                    LessonContent(type: .quiz, question: "When do we say the wudu du'a?", options: ["Before wudu", "During wudu", "After completing wudu", "Anytime"], correctAnswer: 2)
                ]
            ),
            
            // Salah Lessons
            Lesson(
                title: "What is Salah?",
                lessonDescription: "Learn about the five daily prayers",
                category: .salah,
                durationMinutes: 5,
                xpReward: 20,
                order: 6,
                weekNumber: 2
            ),
            Lesson(
                title: "Times of Prayer",
                lessonDescription: "Discover when we pray throughout the day",
                category: .salah,
                durationMinutes: 5,
                xpReward: 20,
                order: 7,
                weekNumber: 2
            ),
            Lesson(
                title: "Preparing for Salah",
                lessonDescription: "Get ready to pray the right way",
                category: .salah,
                durationMinutes: 6,
                xpReward: 25,
                order: 8,
                weekNumber: 2
            ),
            
            // Quran Lessons
            Lesson(
                title: "The Holy Quran",
                lessonDescription: "Learn about Allah's special book",
                category: .quran,
                durationMinutes: 5,
                xpReward: 20,
                order: 9,
                weekNumber: 3
            ),
            Lesson(
                title: "Surah Al-Fatihah",
                lessonDescription: "Learn the opening chapter of the Quran",
                category: .quran,
                durationMinutes: 7,
                xpReward: 30,
                order: 10,
                weekNumber: 3
            ),
            
            // Aqeedah Lessons
            Lesson(
                title: "Belief in Allah",
                lessonDescription: "Learn about the One who created everything",
                category: .aqeedah,
                durationMinutes: 5,
                xpReward: 20,
                order: 11,
                weekNumber: 4
            ),
            Lesson(
                title: "The Prophets",
                lessonDescription: "Meet the special messengers of Allah",
                category: .aqeedah,
                durationMinutes: 6,
                xpReward: 25,
                order: 12,
                weekNumber: 4
            ),
            
            // Adab Lessons
            Lesson(
                title: "Good Manners",
                lessonDescription: "Learn how to be kind and respectful",
                category: .adab,
                durationMinutes: 5,
                xpReward: 20,
                order: 13,
                weekNumber: 5
            ),
            Lesson(
                title: "Helping Others",
                lessonDescription: "Discover the joy of being helpful",
                category: .adab,
                durationMinutes: 5,
                xpReward: 20,
                order: 14,
                weekNumber: 5
            ),
            
            // Du'a Lessons
            Lesson(
                title: "What is Du'a?",
                lessonDescription: "Learn how to talk to Allah",
                category: .duaa,
                durationMinutes: 4,
                xpReward: 15,
                order: 15,
                weekNumber: 6
            ),
            Lesson(
                title: "Morning and Evening Du'as",
                lessonDescription: "Special prayers for morning and night",
                category: .duaa,
                durationMinutes: 6,
                xpReward: 25,
                order: 16,
                weekNumber: 6
            ),
            
            // Seerah Lessons
            Lesson(
                title: "Prophet Muhammad ﷺ",
                lessonDescription: "Meet the best person who ever lived",
                category: .seerah,
                durationMinutes: 5,
                xpReward: 20,
                order: 17,
                weekNumber: 7
            ),
            Lesson(
                title: "The Kindness of the Prophet",
                lessonDescription: "Stories of how kind the Prophet was",
                category: .seerah,
                durationMinutes: 6,
                xpReward: 25,
                order: 18,
                weekNumber: 7
            ),
            
            // Stories
            Lesson(
                title: "The People of the Elephant",
                lessonDescription: "An amazing story from the Quran",
                category: .stories,
                durationMinutes: 7,
                xpReward: 30,
                order: 19,
                weekNumber: 8
            ),
            Lesson(
                title: "The Boy and the King",
                lessonDescription: "A story of bravery and faith",
                category: .stories,
                durationMinutes: 7,
                xpReward: 30,
                order: 20,
                weekNumber: 8
            )
        ]
    }
}
