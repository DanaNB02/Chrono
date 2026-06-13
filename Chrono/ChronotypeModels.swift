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
    case workday = "Work Time"
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
    let isInterlap: Bool
    
    /// Dynamically compares the activity's expected demand against the live HealthKit physical score
    func getSuggestion(actualEnergyScore: Int?) -> String {
        guard let score = actualEnergyScore else {
            return "According to your chronotype, this is an ideal time for this activity. (Enable HealthKit to see live energy adjustments)."
        }
        
        let isUserEnergyHigh = score >= 50
        
        switch expectedDemand {
        case .high:
            if isUserEnergyHigh {
                return "This is your absolute peak, and your energy is high."
            } else {
                return "Your energy is running low for this peak window. Pace yourself with tiny, manageable steps."
            }
            
        case .low, .neutral:
            if isUserEnergyHigh {
                if title.contains("Bedtime") || title.contains("Wind Down") || title.contains("Routine") {
                    return "Your energy is still quite high for bedtime! Channel this extra buzz into quiet reading or journaling to help your system unwind."
                } else if category == .fueling {
                    return "Your energy is solid. Use this meal or break to pace your baseline without overstimulating."
                } else {
                    return "You have an energy surplus right now! Enjoy this light window without overextending your focus."
                }
            } else {
                if category == .fueling {
                    return "Fuel up with clean choices to keep your blood sugar steady through this window."
                }
                return "Perfect timing. Your battery is recharging naturally right now."
            }
        }
    }
}
