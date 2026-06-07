//
//  ScheduleEngine.swift
//  Chrono
//
//  Created by Dana on 18/12/1447 AH.
//

import Foundation

class ScheduleEngine {
    
    // MARK: - UNIFIED SUGGESTIONS (By Category)
    
    static let wakeUpHigh = "Off to a great start! Your battery is fully charged, so use this momentum to ease into your morning."
    static let wakeUpLow = "No need to rush. Take your time getting out of bed and let your body wake up naturally."
    
    static let breakfastHigh = "You're feeling good. A high-protein meal now will keep this steady energy going for hours."
    static let breakfastLow = "Time for a recharge. Grab some protein to kickstart your metabolism and shake off the morning haze."
    
    static let deepFocusHigh = "This is your absolute peak. Put your phone away and tackle your biggest challenge right now."
    static let deepFocusLow = "Today's heavy tasks feel a bit daunting with lower energy. Break them into tiny, bite-sized steps."
    
    static let lunchHigh = "Things are going great. A light, balanced lunch will protect you from the afternoon slump."
    static let lunchLow = "Don't skip this meal. Your body needs some clean fuel right now to prevent a sudden crash later."
    
    static let meetingsHigh = "Perfect time to connect. You have the ideal social presence to lead discussions right now."
    static let meetingsLow = "Energy is running low. Focus on listening, take good notes, and save big decisions for tomorrow."
    
    static let exerciseHigh = "Your body is primed for movement. Hit your workout with full confidence this evening."
    static let exerciseLow = "Skip the heavy lifting today. A gentle walk or some light stretching is exactly what you need."
    
    static let bedHigh = "Even if your mind is still buzzing, it's time to dim the lights and unplug from screens."
    static let bedLow = "Perfect timing. Your battery is empty, and your body is ready for deep, restorative rest."

    // MARK: - BEAR SCHEDULE (The Grounded & Solar-Aligned)
    static let bearSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake up", category: .sleep, window: TimeWindow(startHour: 7, startMinute: 0, endHour: 7, endMinute: 30), expectedDemand: .low, highEnergySuggestion: wakeUpHigh, lowEnergySuggestion: wakeUpLow),
        ChronotypeActivity(title: "High-protein breakfast", category: .fueling, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: breakfastHigh, lowEnergySuggestion: breakfastLow),
        ChronotypeActivity(title: "Deep Focus & Heavy Tasks", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, highEnergySuggestion: deepFocusHigh, lowEnergySuggestion: deepFocusLow),
        ChronotypeActivity(title: "Balanced Lunch", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 30, endHour: 13, endMinute: 30), expectedDemand: .neutral, highEnergySuggestion: lunchHigh, lowEnergySuggestion: lunchLow),
        ChronotypeActivity(title: "Meetings & Collaboration", category: .workday, window: TimeWindow(startHour: 14, startMinute: 0, endHour: 16, endMinute: 0), expectedDemand: .high, highEnergySuggestion: meetingsHigh, lowEnergySuggestion: meetingsLow),
        ChronotypeActivity(title: "Exercise", category: .fitness, window: TimeWindow(startHour: 18, startMinute: 0, endHour: 19, endMinute: 0), expectedDemand: .high, highEnergySuggestion: exerciseHigh, lowEnergySuggestion: exerciseLow),
        ChronotypeActivity(title: "Go to bed", category: .sleep, window: TimeWindow(startHour: 23, startMinute: 0, endHour: 23, endMinute: 59), expectedDemand: .low, highEnergySuggestion: bedHigh, lowEnergySuggestion: bedLow)
    ]
    
    // MARK: - LION SCHEDULE (The Driven Early Riser)
    static let lionSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake up & Hydrate", category: .sleep, window: TimeWindow(startHour: 5, startMinute: 30, endHour: 6, endMinute: 0), expectedDemand: .low, highEnergySuggestion: wakeUpHigh, lowEnergySuggestion: wakeUpLow),
        ChronotypeActivity(title: "Strategic Planning", category: .workday, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 10, endMinute: 0), expectedDemand: .high, highEnergySuggestion: deepFocusHigh, lowEnergySuggestion: deepFocusLow),
        ChronotypeActivity(title: "Lunch", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: lunchHigh, lowEnergySuggestion: lunchLow),
        ChronotypeActivity(title: "Admin & Emails", category: .workday, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 17, endMinute: 0), expectedDemand: .low, highEnergySuggestion: meetingsHigh, lowEnergySuggestion: meetingsLow),
        ChronotypeActivity(title: "Disconnect & Rest", category: .relationships, window: TimeWindow(startHour: 20, startMinute: 0, endHour: 22, endMinute: 0), expectedDemand: .low, highEnergySuggestion: bedHigh, lowEnergySuggestion: bedLow)
    ]
    
    // MARK: - WOLF SCHEDULE (The Creative Night Owl)
    static let wolfSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Struggle to Wake Up", category: .sleep, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 30), expectedDemand: .low, highEnergySuggestion: wakeUpHigh, lowEnergySuggestion: wakeUpLow),
        ChronotypeActivity(title: "Morning Coffee", category: .fueling, window: TimeWindow(startHour: 8, startMinute: 30, endHour: 9, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: breakfastHigh, lowEnergySuggestion: breakfastLow),
        ChronotypeActivity(title: "Light Work & Admin", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .low, highEnergySuggestion: meetingsHigh, lowEnergySuggestion: meetingsLow),
        ChronotypeActivity(title: "Deep Creative Focus", category: .workday, window: TimeWindow(startHour: 14, startMinute: 0, endHour: 18, endMinute: 0), expectedDemand: .high, highEnergySuggestion: deepFocusHigh, lowEnergySuggestion: deepFocusLow),
        ChronotypeActivity(title: "Dinner & Socialize", category: .fueling, window: TimeWindow(startHour: 20, startMinute: 0, endHour: 22, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: lunchHigh, lowEnergySuggestion: lunchLow),
        ChronotypeActivity(title: "Wind Down (Finally)", category: .sleep, window: TimeWindow(startHour: 0, startMinute: 0, endHour: 0, endMinute: 30), expectedDemand: .low, highEnergySuggestion: bedHigh, lowEnergySuggestion: bedLow)
    ]
    
    // MARK: - DOLPHIN SCHEDULE (The Sentry & Light Sleeper)
    static let dolphinSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake up (Did you sleep?)", category: .sleep, window: TimeWindow(startHour: 6, startMinute: 30, endHour: 7, endMinute: 0), expectedDemand: .low, highEnergySuggestion: wakeUpHigh, lowEnergySuggestion: wakeUpLow),
        ChronotypeActivity(title: "Light Exercise", category: .fitness, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: exerciseHigh, lowEnergySuggestion: exerciseLow),
        ChronotypeActivity(title: "Deep Work Window", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, highEnergySuggestion: deepFocusHigh, lowEnergySuggestion: deepFocusLow),
        ChronotypeActivity(title: "Brain Breaks & Admin", category: .workday, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 16, endMinute: 0), expectedDemand: .low, highEnergySuggestion: meetingsHigh, lowEnergySuggestion: meetingsLow),
        ChronotypeActivity(title: "Pre-bed Relaxation", category: .relationships, window: TimeWindow(startHour: 21, startMinute: 0, endHour: 23, endMinute: 30), expectedDemand: .low, highEnergySuggestion: bedHigh, lowEnergySuggestion: bedLow)
    ]
    
    // MARK: - The Array Fetcher
    static func getFullSchedule(for chronotype: Chronotype) -> [ChronotypeActivity] {
        switch chronotype {
        case .bear: return bearSchedule
        case .lion: return lionSchedule
        case .wolf: return wolfSchedule
        case .dolphin: return dolphinSchedule
        }
    }
    
    // MARK: - The Brain
    static func getCurrentActivity(for chronotype: Chronotype, currentTime: Date = Date()) -> ChronotypeActivity {
        let scheduleToSearch = getFullSchedule(for: chronotype)
        if let activeItem = scheduleToSearch.first(where: { $0.window.contains(date: currentTime) }) {
            return activeItem
        }
        return ChronotypeActivity(title: "Free Time", category: .relationships, window: TimeWindow(startHour: 0, startMinute: 0, endHour: 23, endMinute: 59), expectedDemand: .neutral,
                                 highEnergySuggestion: "Unscheduled time! Your energy is great, enjoy doing whatever you love.",
                                 lowEnergySuggestion: "Open schedule. A perfect opportunity to just relax and unwind with zero pressure.")
    }
}
