//
//  MotivationQuotes.swift
//  habitkit
//
//  Rotating daily motivation quotes.
//

import Foundation

struct MotivationQuote: Identifiable {
    let id = UUID()
    let text: String
    let author: String
}

enum MotivationQuotes {
    static let all: [MotivationQuote] = [
        MotivationQuote(
            text: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.",
            author: "Aristotle"
        ),
        MotivationQuote(
            text: "The secret of change is to focus all your energy not on fighting the old, but on building the new.",
            author: "Socrates"
        ),
        MotivationQuote(
            text: "Small daily improvements over time lead to stunning results.",
            author: "Robin Sharma"
        ),
        MotivationQuote(
            text: "You do not rise to the level of your goals. You fall to the level of your systems.",
            author: "James Clear"
        ),
        MotivationQuote(
            text: "The chains of habit are too light to be felt until they are too heavy to be broken.",
            author: "Warren Buffett"
        ),
        MotivationQuote(
            text: "Discipline is choosing between what you want now and what you want most.",
            author: "Abraham Lincoln"
        ),
        MotivationQuote(
            text: "Success is the sum of small efforts, repeated day in and day out.",
            author: "Robert Collier"
        ),
        MotivationQuote(
            text: "Motivation is what gets you started. Habit is what keeps you going.",
            author: "Jim Ryun"
        ),
        MotivationQuote(
            text: "Every action you take is a vote for the type of person you wish to become.",
            author: "James Clear"
        ),
        MotivationQuote(
            text: "First forget inspiration. Habit is more dependable.",
            author: "Octavia Butler"
        ),
        MotivationQuote(
            text: "The only way to do great work is to love what you do.",
            author: "Steve Jobs"
        ),
        MotivationQuote(
            text: "It's not about being the best. It's about being better than you were yesterday.",
            author: "Unknown"
        ),
        MotivationQuote(
            text: "A year from now, you'll wish you had started today.",
            author: "Karen Lamb"
        ),
        MotivationQuote(
            text: "Don't count the days. Make the days count.",
            author: "Muhammad Ali"
        ),
    ]

    /// Get a quote based on the current day (rotates daily)
    static var today: MotivationQuote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return all[dayOfYear % all.count]
    }
}
