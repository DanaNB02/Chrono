//
//  ScheduleEngine.swift
//  Chrono
//
//  Created by Dana on 18/12/1447 AH.
//

import Foundation

class ScheduleEngine {
    
    // MARK: - LION SCHEDULE 🦁
    static let lionSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake Up", category: .sleep, window: TimeWindow(startHour: 5, startMinute: 30, endHour: 6, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Breakfast (High-protein)", category: .fueling, window: TimeWindow(startHour: 6, startMinute: 0, endHour: 7, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Gentle Movement (Yoga/Stretching)", category: .fitness, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 9, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Deep Focus & Heavy Task", category: .workday, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, isInterlap: false),
        
        // Nested micro events inside Deep Focus & Heavy Task
        ChronotypeActivity(title: "Coffee Break (Caffeine Fix)", category: .fueling, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 10, endMinute: 0), expectedDemand: .neutral, isInterlap: true),
        ChronotypeActivity(title: "Snack Time", category: .fueling, window: TimeWindow(startHour: 9, startMinute: 0, endHour: 9, endMinute: 30), expectedDemand: .neutral, isInterlap: true),
        
        ChronotypeActivity(title: "Lunch (Balanced/Light)", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Administrative Work / Lighter Tasks", category: .workday, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 14, endMinute: 30), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Strength Training (Resistance)", category: .fitness, window: TimeWindow(startHour: 14, startMinute: 30, endHour: 17, endMinute: 0), expectedDemand: .high, isInterlap: false),
        ChronotypeActivity(title: "Running / Yoga", category: .fitness, window: TimeWindow(startHour: 17, startMinute: 30, endHour: 18, endMinute: 0), expectedDemand: .high, isInterlap: false),
        ChronotypeActivity(title: "Dinner (Light/Healthy)", category: .fueling, window: TimeWindow(startHour: 18, startMinute: 0, endHour: 19, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Bedtime Routine (Relaxing)", category: .sleep, window: TimeWindow(startHour: 19, startMinute: 0, endHour: 22, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Bedtime / Lights Out", category: .sleep, window: TimeWindow(startHour: 22, startMinute: 0, endHour: 22, endMinute: 30), expectedDemand: .low, isInterlap: false)
    ]

    // MARK: - DOLPHIN SCHEDULE 🐬
    static let dolphinSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake Up", category: .sleep, window: TimeWindow(startHour: 6, startMinute: 30, endHour: 7, endMinute: 15), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Weekend Sleep-In Limit", category: .sleep, window: TimeWindow(startHour: 7, startMinute: 15, endHour: 8, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Light Cardio (Brisk Walk/Cycle)", category: .fitness, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 9, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Organization & Admin Planning", category: .workday, window: TimeWindow(startHour: 9, startMinute: 0, endHour: 10, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Prime Productivity & Focus Time", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, isInterlap: false),
        
        // Nested Strength Training inside Focus Time Peak
        ChronotypeActivity(title: "Strength Training", category: .fitness, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, isInterlap: true),
        
        ChronotypeActivity(title: "Lunch (Light & Filling)", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Post-Lunch Energy Activity", category: .workday, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 15, endMinute: 0), expectedDemand: .high, isInterlap: false),
        
        // Nested Team Sports inside Post-Lunch window
        ChronotypeActivity(title: "Team Sports", category: .fitness, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 15, endMinute: 0), expectedDemand: .high, isInterlap: true),
        
        ChronotypeActivity(title: "Snack Time & Low-Effort Admin", category: .fueling, window: TimeWindow(startHour: 15, startMinute: 0, endHour: 17, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Team Sports / Aerobic Fitness", category: .fitness, window: TimeWindow(startHour: 17, startMinute: 0, endHour: 19, endMinute: 0), expectedDemand: .high, isInterlap: false),
        
        // Nested Relaxing Yoga inside Aerobic Fitness Window
        ChronotypeActivity(title: "Relaxing Yoga / Stretching", category: .fitness, window: TimeWindow(startHour: 18, startMinute: 0, endHour: 19, endMinute: 0), expectedDemand: .low, isInterlap: true),
        
        ChronotypeActivity(title: "Peak Patience Window", category: .relationships, window: TimeWindow(startHour: 19, startMinute: 0, endHour: 19, endMinute: 30), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Dinner (Carb-Heavy)", category: .fueling, window: TimeWindow(startHour: 19, startMinute: 30, endHour: 22, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Yoga / Screenless Decompression", category: .fitness, window: TimeWindow(startHour: 22, startMinute: 0, endHour: 23, endMinute: 30), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Bedtime / Lights Out", category: .sleep, window: TimeWindow(startHour: 23, startMinute: 30, endHour: 24, endMinute: 0), expectedDemand: .low, isInterlap: false)
    ]

    // MARK: - BEAR SCHEDULE 🐻
    static let bearSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake Up", category: .sleep, window: TimeWindow(startHour: 7, startMinute: 0, endHour: 7, endMinute: 30), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Breakfast (High-Protein/Low-Carb)", category: .fueling, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        
        // Nested Morning Run inside Breakfast window
        ChronotypeActivity(title: "Morning Run (Light Jog)", category: .fitness, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 0), expectedDemand: .low, isInterlap: true),
        
        ChronotypeActivity(title: "Coffee Break (Delayed Caffeine)", category: .fueling, window: TimeWindow(startHour: 9, startMinute: 30, endHour: 10, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Strenuous Concentration Peak", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, isInterlap: false),
        ChronotypeActivity(title: "Lunch (Medium & Balanced)", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        
        // Nested Strength Training inside Lunch Hour
        ChronotypeActivity(title: "Strength Training (Midday Lift)", category: .fitness, window: TimeWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .high, isInterlap: true),
        
        ChronotypeActivity(title: "Energy Decrease Phase (Busywork)", category: .workday, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 15, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Low Energy Phase (Lighter Tasks)", category: .workday, window: TimeWindow(startHour: 15, startMinute: 0, endHour: 16, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Afternoon Snack", category: .fueling, window: TimeWindow(startHour: 16, startMinute: 0, endHour: 17, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Yoga Session", category: .fitness, window: TimeWindow(startHour: 17, startMinute: 0, endHour: 18, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Dinner (Easily Digestible)", category: .fueling, window: TimeWindow(startHour: 18, startMinute: 0, endHour: 19, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Bedtime Routine (Relaxation)", category: .relationships, window: TimeWindow(startHour: 19, startMinute: 0, endHour: 23, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Bedtime / Lights Out", category: .sleep, window: TimeWindow(startHour: 23, startMinute: 0, endHour: 23, endMinute: 30), expectedDemand: .low, isInterlap: false)
    ]

    // MARK: - WOLF SCHEDULE 🐺
    static let wolfSchedule: [ChronotypeActivity] = [
        ChronotypeActivity(title: "Wake Up", category: .sleep, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Morning Yoga (Gentle)", category: .fitness, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 9, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Breakfast (High-Protein)", category: .fueling, window: TimeWindow(startHour: 9, startMinute: 0, endHour: 10, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Energy Builds Up (Lighter Tasks)", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 11, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Coffee Break & Pre-Focus Prep", category: .fueling, window: TimeWindow(startHour: 11, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        ChronotypeActivity(title: "Balanced Lunch & Deep Task Kickoff", category: .fueling, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 16, endMinute: 0), expectedDemand: .high, isInterlap: false),
        ChronotypeActivity(title: "Snack & Intense Workout Window", category: .fitness, window: TimeWindow(startHour: 16, startMinute: 0, endHour: 20, endMinute: 0), expectedDemand: .high, isInterlap: false),
        ChronotypeActivity(title: "Dinner (Carb-Heavy Unwind)", category: .fueling, window: TimeWindow(startHour: 20, startMinute: 0, endHour: 21, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        
        // Nested Relaxing activities inside Dinner hour
        ChronotypeActivity(title: "Relaxing Activities (Calm Mind)", category: .fitness, window: TimeWindow(startHour: 20, startMinute: 0, endHour: 21, endMinute: 0), expectedDemand: .low, isInterlap: true),
        
        ChronotypeActivity(title: "Bedtime Routine (Ditch Gadgets)", category: .relationships, window: TimeWindow(startHour: 21, startMinute: 0, endHour: 24, endMinute: 0), expectedDemand: .low, isInterlap: false),
        ChronotypeActivity(title: "Bedtime / Lights Out", category: .sleep, window: TimeWindow(startHour: 24, startMinute: 0, endHour: 24, endMinute: 30), expectedDemand: .low, isInterlap: false)
    ]

    // MARK: - FETCHERS
    static func getFullSchedule(for chronotype: Chronotype) -> [ChronotypeActivity] {
        switch chronotype {
        case .bear: return bearSchedule
        case .lion: return lionSchedule
        case .wolf: return wolfSchedule
        case .dolphin: return dolphinSchedule
        }
    }
    
    static func getCurrentActivity(for chronotype: Chronotype, currentTime: Date = Date()) -> ChronotypeActivity {
        let scheduleToSearch = getFullSchedule(for: chronotype)
        if let activeItem = scheduleToSearch.first(where: { !$0.isInterlap && $0.window.contains(date: currentTime) }) {
            return activeItem
        }
        return ChronotypeActivity(title: "Free Time", category: .relationships, window: TimeWindow(startHour: 0, startMinute: 0, endHour: 23, endMinute: 59), expectedDemand: .neutral, isInterlap: false)
    }
}
