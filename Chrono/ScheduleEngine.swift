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
        
        ChronotypeActivity(title: "Breakfast", category: .fueling, window: TimeWindow(startHour: 6, startMinute: 0, endHour: 7, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
                
        ChronotypeActivity(title: "Deep Focus & Heavy Task", category: .workday, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, isInterlap: false),
        
        ChronotypeActivity(title: "Coffee Break", category: .fueling, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 10, endMinute: 0), expectedDemand: .neutral, isInterlap: true),
        
        ChronotypeActivity(title: "Snack Time", category: .fueling, window: TimeWindow(startHour: 9, startMinute: 0, endHour: 9, endMinute: 30), expectedDemand: .neutral, isInterlap: true),
        
        ChronotypeActivity(title: "Lunch", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        
        ChronotypeActivity(title: "Lighter Tasks", category: .workday, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 14, endMinute: 30), expectedDemand: .low, isInterlap: false),
        
        ChronotypeActivity(title: "Dinner", category: .fueling, window: TimeWindow(startHour: 18, startMinute: 0, endHour: 19, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
        
        ChronotypeActivity(title: "Bedtime Routine (Relaxing)", category: .sleep, window: TimeWindow(startHour: 19, startMinute: 0, endHour: 22, endMinute: 0), expectedDemand: .low, isInterlap: false),
        
        ChronotypeActivity(title: "Bedtime / Lights Out", category: .sleep, window: TimeWindow(startHour: 22, startMinute: 0, endHour: 22, endMinute: 30), expectedDemand: .low, isInterlap: false)
    ]

    // MARK: - DOLPHIN SCHEDULE 🐬
        static let dolphinSchedule: [ChronotypeActivity] = [
            ChronotypeActivity(title: "Wake Up", category: .sleep, window: TimeWindow(startHour: 6, startMinute: 30, endHour: 7, endMinute: 15), expectedDemand: .low, isInterlap: false),
            
            ChronotypeActivity(title: "Breakfast", category: .fueling, window: TimeWindow(startHour: 7, startMinute: 15, endHour: 8, endMinute: 30), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Lighter Tasks", category: .workday, window: TimeWindow(startHour: 8, startMinute: 30, endHour: 10, endMinute: 0), expectedDemand: .low, isInterlap: false),
            
            ChronotypeActivity(title: "Coffee Break", category: .fueling, window: TimeWindow(startHour: 8, startMinute: 30, endHour: 9, endMinute: 30), expectedDemand: .neutral, isInterlap: true),
            
            ChronotypeActivity(title: "Deep Focus & Heavy Task", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, isInterlap: false),
            
            ChronotypeActivity(title: "Lunch", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Snack Time", category: .fueling, window: TimeWindow(startHour: 15, startMinute: 0, endHour: 16, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Dinner", category: .fueling, window: TimeWindow(startHour: 19, startMinute: 30, endHour: 22, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Bedtime Routine (Relaxing)", category: .sleep, window: TimeWindow(startHour: 22, startMinute: 0, endHour: 23, endMinute: 30), expectedDemand: .low, isInterlap: false),
            
            ChronotypeActivity(title: "Bedtime / Lights Out", category: .sleep, window: TimeWindow(startHour: 23, startMinute: 30, endHour: 24, endMinute: 0), expectedDemand: .low, isInterlap: false)
        ]

    // MARK: - BEAR SCHEDULE 🐻
        static let bearSchedule: [ChronotypeActivity] = [
            ChronotypeActivity(title: "Wake Up", category: .sleep, window: TimeWindow(startHour: 7, startMinute: 0, endHour: 7, endMinute: 30), expectedDemand: .low, isInterlap: false),
            
            ChronotypeActivity(title: "Breakfast", category: .fueling, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 30), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Deep Focus & Heavy Task", category: .workday, window: TimeWindow(startHour: 10, startMinute: 0, endHour: 12, endMinute: 0), expectedDemand: .high, isInterlap: false),
            
            ChronotypeActivity(title: "Coffee Break", category: .fueling, window: TimeWindow(startHour: 9, startMinute: 0, endHour: 10, endMinute: 0), expectedDemand: .neutral, isInterlap: true),
            
            ChronotypeActivity(title: "Snack Time", category: .fueling, window: TimeWindow(startHour: 14, startMinute: 0, endHour: 14, endMinute: 30), expectedDemand: .neutral, isInterlap: true),
            
            ChronotypeActivity(title: "Lunch", category: .fueling, window: TimeWindow(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Lighter Tasks", category: .workday, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 17, endMinute: 0), expectedDemand: .low, isInterlap: false),
            
            ChronotypeActivity(title: "Dinner", category: .fueling, window: TimeWindow(startHour: 18, startMinute: 0, endHour: 19, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Bedtime Routine (Relaxing)", category: .sleep, window: TimeWindow(startHour: 19, startMinute: 0, endHour: 23, endMinute: 0), expectedDemand: .low, isInterlap: false),
            
            ChronotypeActivity(title: "Bedtime / Lights Out", category: .sleep, window: TimeWindow(startHour: 23, startMinute: 0, endHour: 23, endMinute: 30), expectedDemand: .low, isInterlap: false)
        ]

    // MARK: - WOLF SCHEDULE 🐺
        static let wolfSchedule: [ChronotypeActivity] = [
            ChronotypeActivity(title: "Wake Up", category: .sleep, window: TimeWindow(startHour: 7, startMinute: 30, endHour: 8, endMinute: 0), expectedDemand: .low, isInterlap: false),
            
            ChronotypeActivity(title: "Breakfast", category: .fueling, window: TimeWindow(startHour: 8, startMinute: 0, endHour: 9, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Lighter Tasks", category: .workday, window: TimeWindow(startHour: 9, startMinute: 0, endHour: 13, endMinute: 0), expectedDemand: .low, isInterlap: false),
            
            ChronotypeActivity(title: "Coffee Break", category: .fueling, window: TimeWindow(startHour: 11, startMinute: 30, endHour: 12, endMinute: 0), expectedDemand: .neutral, isInterlap: true),
            
            ChronotypeActivity(title: "Lunch", category: .fueling, window: TimeWindow(startHour: 13, startMinute: 0, endHour: 14, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Deep Focus & Heavy Task", category: .workday, window: TimeWindow(startHour: 14, startMinute: 0, endHour: 18, endMinute: 0), expectedDemand: .high, isInterlap: false),
            
            ChronotypeActivity(title: "Snack Time", category: .fueling, window: TimeWindow(startHour: 16, startMinute: 0, endHour: 16, endMinute: 30), expectedDemand: .neutral, isInterlap: true),
            
            ChronotypeActivity(title: "Dinner", category: .fueling, window: TimeWindow(startHour: 20, startMinute: 0, endHour: 21, endMinute: 0), expectedDemand: .neutral, isInterlap: false),
            
            ChronotypeActivity(title: "Bedtime Routine (Relaxing)", category: .sleep, window: TimeWindow(startHour: 21, startMinute: 0, endHour: 23, endMinute: 30), expectedDemand: .low, isInterlap: false),
            
            ChronotypeActivity(title: "Bedtime / Lights Out", category: .sleep, window: TimeWindow(startHour: 23, startMinute: 30, endHour: 24, endMinute: 0), expectedDemand: .low, isInterlap: false)
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
