//
//  ChronotypeModels.swift
//  Chrono
//
//  Created by Dana on 18/12/1447 AH.
//

import Foundation

// MARK: - Enums

enum Chronotype: String, CaseIterable, Codable {
    case bear = "Bear"
    case lion = "Lion"
    case wolf = "Wolf"
    case dolphin = "Dolphin"
}

enum EnergyDemand {
    case high    // Requires brainpower or physical exertion
    case low     // Recovery, admin, winding down
    case neutral // Routine/Fueling (eating, coffee)
}

enum ActivityCategory: String {
    case sleep = "Sleep Schedule"
    case workday = "Workday"
    case relationships = "Relationships"
    case fueling = "Sip, Snack, and Splurge"
    case fitness = "Fitness Goals"
}

// MARK: - Time Management

struct TimeWindow {
    let startHour: Int   // Military time (0-23)
    let startMinute: Int // 0-59
    let endHour: Int
    let endMinute: Int
    
    /// Checks if the iPhone's current time falls inside this exact window
    func contains(date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)
        
        let currentTotalMinutes = (currentHour * 60) + currentMinute
        let startTotalMinutes = (startHour * 60) + startMinute
        let endTotalMinutes = (endHour * 60) + endMinute
        
        // Handle overnight windows (e.g., 11:30 PM to 6:30 AM for the Dolphin)
        if startTotalMinutes > endTotalMinutes {
            return currentTotalMinutes >= startTotalMinutes || currentTotalMinutes <= endTotalMinutes
        }
        
        return currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < endTotalMinutes
    }
    
    // Helper to easily display "7:00 AM - 9:00 AM" in your UI later
    var displayString: String {
        let startPeriod = startHour >= 12 ? "PM" : "AM"
        let endPeriod = endHour >= 12 ? "PM" : "AM"
        
        let displayStartHour = startHour % 12 == 0 ? 12 : startHour % 12
        let displayEndHour = endHour % 12 == 0 ? 12 : endHour % 12
        
        let startMinStr = startMinute == 0 ? "" : String(format: ":%02d", startMinute)
        let endMinStr = endMinute == 0 ? "" : String(format: ":%02d", endMinute)
        
        return "\(displayStartHour)\(startMinStr) \(startPeriod) - \(displayEndHour)\(endMinStr) \(endPeriod)"
    }
}



// MARK: - Core Model

struct ChronotypeActivity: Identifiable {
    let id = UUID()
    let title: String
    let category: ActivityCategory
    let window: TimeWindow
    let expectedDemand: EnergyDemand
    
    // The customized UI strings based on the 50% HealthKit threshold
    let highEnergySuggestion: String
    let lowEnergySuggestion: String
    
    /// The logic engine calls this to get the exact text for the UI
    func getSuggestion(actualEnergyScore: Int?) -> String {
        guard let score = actualEnergyScore else {
            // Fallback if they denied HealthKit (gray circle)
            return "According to your chronotype, this is an ideal time for this activity. (Enable HealthKit to see live energy adjustments)."
        }
        
        // The 50% Pivot Point
        if score >= 50 {
            return highEnergySuggestion
        } else {
            return lowEnergySuggestion
        }
    }
}
