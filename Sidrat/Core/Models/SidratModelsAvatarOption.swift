//
//  AvatarOption.swift
//  Sidrat
//
//  Child-friendly avatar options with animal emojis
//

import SwiftUI

/// Avatar options for child profiles
/// Uses culturally appropriate animal emojis with distinct colors
enum AvatarOption: String, CaseIterable, Codable, Identifiable {
    case cat = "🐱"
    case dog = "🐶"
    case rabbit = "🐰"
    case bird = "🐦"
    case fish = "🐠"
    case turtle = "🐢"
    case panda = "🐼"
    case koala = "🐨"
    case lion = "🦁"
    case elephant = "🐘"
    case owl = "🦉"
    case butterfly = "🦋"
    
    var id: String { rawValue }
    
    /// The emoji representation
    var emoji: String { rawValue }
    
    /// Background color for the avatar bubble
    var backgroundColor: Color {
        switch self {
        case .cat: return Color(hex: "FF9500") // Orange
        case .dog: return Color(hex: "A2845E") // Brown
        case .rabbit: return Color(hex: "FF69B4") // Pink
        case .bird: return Color(hex: "5AC8FA") // Light Blue
        case .fish: return Color(hex: "4CD964") // Green
        case .turtle: return Color(hex: "34C759") // Emerald
        case .panda: return Color(hex: "8E8E93") // Gray
        case .koala: return Color(hex: "AF52DE") // Purple
        case .lion: return Color(hex: "FFCC00") // Gold
        case .elephant: return Color(hex: "5856D6") // Indigo
        case .owl: return Color(hex: "FF6B6B") // Red
        case .butterfly: return Color(hex: "FF2D92") // Magenta
        }
    }
    
    /// Accessible label for VoiceOver
    var accessibilityLabel: String {
        switch self {
        case .cat: return "Cat"
        case .dog: return "Dog"
        case .rabbit: return "Rabbit"
        case .bird: return "Bird"
        case .fish: return "Fish"
        case .turtle: return "Turtle"
        case .panda: return "Panda"
        case .koala: return "Koala"
        case .lion: return "Lion"
        case .elephant: return "Elephant"
        case .owl: return "Owl"
        case .butterfly: return "Butterfly"
        }
    }
}

