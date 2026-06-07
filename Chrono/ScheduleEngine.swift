//
//  ScheduleEngine.swift
//  Chrono
//
//  Created by Dana on 18/12/1447 AH.
//

import Foundation

class ScheduleEngine {
    
    // MARK: - BEAR SCHEDULE
    static let bearSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake up", category: .sleep, window: TimeWindow(startHour: 7, startMinute: 0, endHour: 7, endMinute: 30), expectedDemand: .low, highEnergySuggestion: "Bonus Fuel: You are waking up with a surprisingly full battery. Use this momentum to ease into your day.", lowEnergySuggestion: "Slow Start: Your body is still waking up. Ease into your day and don't rush."),
        ChronotypeActivity(title: "High-protein breakfast", category: .fueling, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: "Fuel Up: Your energy is great. Get your protein in now.", lowEnergySuggestion: "Refuel Required: Your battery is low. You need protein to kickstart your metabolism."),
        ChronotypeActivity(title: "Deep Focus & Heavy Tasks", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, highEnergySuggestion: "Perfect Sync: Your biological clock and physical energy are aligned. Put your phone away and execute.", lowEnergySuggestion: "Energy Debt: Your schedule calls for high output, but you are draining. Take a walk before diving in."),
        ChronotypeActivity(title: "Balanced Lunch", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 30, endHour: 13, endMinute: 30), expectedDemand: .neutral, highEnergySuggestion: "Fuel Up: Energy is holding strong. Maintain this momentum.", lowEnergySuggestion: "Refuel Required: Do not skip this scheduled fueling window, or you will crash."),
        ChronotypeActivity(title: "Meetings & Collaboration", category: .workday, window: TimeWindow(startHour: 14, startMinute: 0, endHour: 16, endMinute: 0), expectedDemand: .high, highEnergySuggestion: "Social Peak: You have the energy to engage and lead right now.", lowEnergySuggestion: "Battery Low: Let others do the talking if possible. Conserve your energy."),
        ChronotypeActivity(title: "Exercise", category: .fitness, window: TimeWindow(startHour: 18, startMinute: 0, endHour: 19, endMinute: 0), expectedDemand: .high, highEnergySuggestion: "Peak Output: Hit the gym hard, your body is ready.", lowEnergySuggestion: "Recovery Mode: Skip the heavy lifting. Opt for light stretching or a walk."),
        ChronotypeActivity(title: "Go to bed", category: .sleep, window: TimeWindow(startHour: 23, startMinute: 0, endHour: 23, endMinute: 59), expectedDemand: .low, highEnergySuggestion: "Wind Down: You still have energy, but it's time to disconnect.", lowEnergySuggestion: "System Empty: Perfect timing to go to sleep and recharge.")
    ]
    
    // MARK: - LION SCHEDULE
    static let lionSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake up & Hydrate", category: .sleep, window: TimeWindow(startHour: 5, startMinute: 30, endHour: 6, endMinute: 0), expectedDemand: .low, highEnergySuggestion: "Lion Mode: You are awake and alert. Drink water and start moving.", lowEnergySuggestion: "Even Lions need a minute. Hydrate before doing anything else."),
        ChronotypeActivity(title: "Strategic Planning", category: .workday, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 10, endMinute: 0), expectedDemand: .high, highEnergySuggestion: "Absolute Peak: You are the sharpest person in the room right now. Tackle your hardest problem.", lowEnergySuggestion: "Slight Dip: You should be peaking. Grab a coffee and push through."),
        ChronotypeActivity(title: "Lunch", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: "Keep the fire burning. Eat a medium-sized meal.", lowEnergySuggestion: "You are crashing early. Prioritize clean energy, no heavy carbs."),
        ChronotypeActivity(title: "Admin & Emails", category: .workday, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 17, endMinute: 0), expectedDemand: .low, highEnergySuggestion: "Coast through your afternoon tasks with ease.", lowEnergySuggestion: "Your Lion battery is dying. Stick to easy, mindless tasks."),
        ChronotypeActivity(title: "Disconnect & Rest", category: .relationships, window: TimeWindow(startHour: 20, startMinute: 0, endHour: 22, endMinute: 0), expectedDemand: .low, highEnergySuggestion: "You survived the day. Enjoy your evening.", lowEnergySuggestion: "You are completely exhausted. Get to bed as soon as possible.")
    ]
    
    // MARK: - WOLF SCHEDULE
    static let wolfSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Struggle to Wake Up", category: .sleep, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 30), expectedDemand: .low, highEnergySuggestion: "Rare Morning Energy: Use this anomaly to get ahead of your day.", lowEnergySuggestion: "Classic Wolf: Do not hit snooze again. Get up and find sunlight."),
        ChronotypeActivity(title: "Morning Coffee", category: .fueling, window: TimeWindow(startHour: 8, startMinute: 30, endHour: 9, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: "Hydrate first, then caffeinate.", lowEnergySuggestion: "You desperately need this coffee. Drink up."),
        ChronotypeActivity(title: "Light Work & Admin", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .low, highEnergySuggestion: "You are warming up faster than usual.", lowEnergySuggestion: "Your brain is still asleep. Stick to checking off easy boxes."),
        ChronotypeActivity(title: "Deep Creative Focus", category: .workday, window: TimeWindow(startHour: 14, startMinute: 0, endHour: 18, endMinute: 0), expectedDemand: .high, highEnergySuggestion: "Wolf Peak: You are entering flow state. Do your most important work right now.", lowEnergySuggestion: "Brain Fog: You should be peaking. Get some fresh air to trigger your focus."),
        ChronotypeActivity(title: "Dinner & Socialize", category: .fueling, window: TimeWindow(startHour: 20, startMinute: 0, endHour: 22, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: "You are still wide awake. Enjoy the evening.", lowEnergySuggestion: "Rare evening crash. Take it easy tonight."),
        ChronotypeActivity(title: "Wind Down (Finally)", category: .sleep, window: TimeWindow(startHour: 0, startMinute: 0, endHour: 0, endMinute: 30), expectedDemand: .low, highEnergySuggestion: "Turn off the screens. It's time to force a shutdown.", lowEnergySuggestion: "Your late-night energy is finally gone. Go to sleep.")
    ]
    
    // MARK: - DOLPHIN SCHEDULE
    static let dolphinSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake up (Did you sleep?)", category: .sleep, window: TimeWindow(startHour: 6, startMinute: 30, endHour: 7, endMinute: 0), expectedDemand: .low, highEnergySuggestion: "Miracle Morning: You actually got some rest. Enjoy it.", lowEnergySuggestion: "Erratic Sleep: You tossed and turned. Don't stress, just start the day."),
        ChronotypeActivity(title: "Light Exercise", category: .fitness, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 0), expectedDemand: .neutral, highEnergySuggestion: "Burn off some of that nervous energy.", lowEnergySuggestion: "Just do some light stretching to wake your nervous system up."),
        ChronotypeActivity(title: "Deep Work Window", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, highEnergySuggestion: "Hyper-Focus: Your anxiety is channeled into productivity. Go.", lowEnergySuggestion: "Distracted: Your brain is scattered. Break your tasks into 5-minute chunks."),
        ChronotypeActivity(title: "Brain Breaks & Admin", category: .workday, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 16, endMinute: 0), expectedDemand: .low, highEnergySuggestion: "Riding a decent wave of energy. Keep moving.", lowEnergySuggestion: "Dolphin Crash: Step away from the screen for 15 minutes."),
        ChronotypeActivity(title: "Pre-bed Relaxation", category: .relationships, window: TimeWindow(startHour: 21, startMinute: 0, endHour: 23, endMinute: 30), expectedDemand: .low, highEnergySuggestion: "Start dimming the lights to trick your brain.", lowEnergySuggestion: "You are exhausted, which is good. Don't look at your phone in bed.")
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
        return ChronotypeActivity(title: "Free Time", category: .relationships, window: TimeWindow(startHour: 0, startMinute: 0, endHour: 23, endMinute: 59), expectedDemand: .neutral, highEnergySuggestion: "No scheduled tasks. Your energy is great, enjoy the free time!", lowEnergySuggestion: "No scheduled tasks. Use this gap to rest and recover.")
    }
}
