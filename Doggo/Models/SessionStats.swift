//
//  SessionStats.swift
//  Doggo
//

import Foundation

/// Statistiques d'une partie, calculées à partir de l'historique des points.
struct SessionStats {
    struct DayCount: Identifiable {
        let day: Date
        let count: Int
        var id: Date { day }
    }

    struct PlayerDay: Identifiable {
        let playerID: String
        let day: Date
        let count: Int
        var id: String { "\(playerID)-\(day.timeIntervalSince1970)" }
    }

    let totalPoints: Int
    let today: Int
    let bestDay: DayCount?
    let currentStreak: Int
    let longestStreak: Int
    let activeDays: Int
    let lastSevenDays: [PlayerDay]
    let todayByPlayer: [String: Int]
    let favoriteHour: Int?

    init(events: [ScoreEvent], calendar: Calendar = .current, now: Date = Date()) {
        let valid = events.filter { !$0.undone }
        totalPoints = valid.count

        let byDay = Dictionary(grouping: valid) { calendar.startOfDay(for: $0.createdAt) }
        let days = byDay.keys.sorted()
        activeDays = days.count

        let todayStart = calendar.startOfDay(for: now)
        let todayEvents = byDay[todayStart] ?? []
        today = todayEvents.count
        todayByPlayer = Dictionary(grouping: todayEvents, by: \.playerID).mapValues(\.count)

        bestDay = byDay.map { DayCount(day: $0.key, count: $0.value.count) }
            .max { $0.count != $1.count ? $0.count < $1.count : $0.day < $1.day }

        // Séries de jours consécutifs avec au moins un point.
        var longest = 0
        var run = 0
        var previous: Date?
        for day in days {
            if let previous, let next = calendar.date(byAdding: .day, value: 1, to: previous), calendar.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            previous = day
        }
        longestStreak = longest

        var streak = 0
        var cursor = todayStart
        // La série reste « en cours » si le dernier point date d'hier.
        if byDay[cursor] == nil, let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) {
            cursor = yesterday
        }
        while byDay[cursor] != nil {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previousDay
        }
        currentStreak = streak

        var week: [PlayerDay] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { continue }
            let perPlayer = Dictionary(grouping: byDay[day] ?? [], by: \.playerID)
            for (playerID, items) in perPlayer {
                week.append(PlayerDay(playerID: playerID, day: day, count: items.count))
            }
        }
        lastSevenDays = week

        let hours = Dictionary(grouping: valid) { calendar.component(.hour, from: $0.createdAt) }
        favoriteHour = hours.max { $0.value.count < $1.value.count }?.key
    }
}
