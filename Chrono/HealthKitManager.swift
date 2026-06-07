//
//  HealthKitManager.swift
//  Chrono
//
//  Created by Dane on 18/12/1447 AH.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    
    let healthStore = HKHealthStore()
    
    // MARK: - Health Types to Read
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let rhrType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
    
    /// Requests access to Apple Health
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let typesToRead: Set<HKObjectType> = [sleepType, hrvType, rhrType]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            return true
        } catch {
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// The Core Math Matrix: Fetches metrics and computes the baseline 0-100 score
        func calculateMorningBaseline() async -> Double? {
            
            // 🚨 SIMULATOR OVERRIDE IS ACTIVE FOR YOUR SUNDAY DEMO
            #if targetEnvironment(simulator)
            return 94.0
            #else
            
            // PHYSICAL DEVICE LOGIC
            let now = Date()
            let calendar = Calendar.current
            let twentyFourHoursAgo = calendar.date(byAdding: .hour, value: -24, to: now)!
            let predicate = HKQuery.predicateForSamples(withStart: twentyFourHoursAgo, end: now, options: .strictStartDate)
            
            let sleepMinutes = await fetchLastNightSleep(predicate: predicate)
            let hrvValue = await fetchLastHRV(predicate: predicate)
            let rhrValue = await fetchLastRHR(predicate: predicate)
            
            // THE PRIVACY CHECK:
            // If all three return nil, it means the user tapped "Don't Allow" or has zero data.
            if sleepMinutes == nil && hrvValue == nil && rhrValue == nil {
                return nil // This tells ContentView to show the "Health Data Unavailable" screen
            }
            
            // If they DID allow it, we use their real data (or safe fallbacks if only one metric is missing)
            let finalSleep = sleepMinutes ?? 450.0
            let finalHRV = hrvValue ?? 50.0
            let finalRHR = rhrValue ?? 65.0
            
            // The Math
            let sleepScore = min((finalSleep / 480.0) * 50.0, 50.0)
            let hrvScore = min((finalHRV / 50.0) * 30.0, 30.0)
            let rhrScore = min((65.0 / finalRHR) * 20.0, 20.0)
            
            let totalScore = sleepScore + hrvScore + rhrScore
            return min(max(totalScore, 0.0), 100.0)
            
            #endif
        }
    
    // MARK: - Background Fetch Helpers
    // Notice these also have a 'Double?' so they can return nil instead of fake numbers
    
    private func fetchLastNightSleep(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in }
        
        return await withCheckedContinuation { continuation in
            let sampleQuery = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil) // Returns nil instead of 420.0!
                    return
                }
                
                let totalAsleepTime = sleepSamples
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                
                let minutes = totalAsleepTime / 60.0
                continuation.resume(returning: minutes > 0 ? minutes : nil)
            }
            healthStore.execute(sampleQuery)
        }
    }
    
    private func fetchLastHRV(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil) // Returns nil instead of 48.0!
                    return
                }
                let hrvInMs = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: hrvInMs)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLastRHR(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: rhrType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil) // Returns nil instead of 68.0!
                    return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: bpm)
            }
            healthStore.execute(query)
        }
    }
}
