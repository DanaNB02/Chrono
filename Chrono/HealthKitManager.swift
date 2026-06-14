//
//  HealthKitManager.swift
//  Chrono
//
//  Created by Reema on 18/12/1447 AH.
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
    private let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    
    /// Requests access to Apple Health
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let typesToRead: Set<HKObjectType> = [
            sleepType,
            hrvType,
            rhrType,
            activeCaloriesType,
            heartRateType
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            return true
        } catch {
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// The Updated Core Math Matrix with Real-Time Console Telemetry
    func calculateLiveEnergyScore() async -> Double? {
        
        #if targetEnvironment(simulator)
        print("ℹ️ [HealthKit Engine] Running on Simulator - Returning empty/nil to trigger baseline flow.")
        return nil
        #else
        
        print("\n📊 [HealthKit Engine] جاري بدء فحص البيانات الحيوية الفلكية والنشاط اليومي...")
        
        let now = Date()
        let calendar = Calendar.current
        
        // Time window predicates
        let thirtySixHoursAgo = calendar.date(byAdding: .hour, value: -36, to: now)!
        let generalPredicate = HKQuery.predicateForSamples(withStart: thirtySixHoursAgo, end: now, options: [])
        let todayPredicate = HKQuery.predicateForSamples(withStart: calendar.startOfDay(for: now), end: now, options: [])
        
        // Fetch raw values from Apple Health
        let sleepMinutes = await fetchLastNightSleep(predicate: generalPredicate)
        let hrvValue = await fetchLastHRV(predicate: generalPredicate)
        let rhrValue = await fetchLastRHR(predicate: generalPredicate)
        let activeCalories = await fetchTodayActiveCalories(predicate: todayPredicate)
        let hrSpikes = await fetchTodayHeartRateSpikes(predicate: todayPredicate, baselineRHR: rhrValue ?? 65.0)
        
        print("--------- 🩺 تقرير المستشعرات الحالية ---------")
        if let sleep = sleepMinutes {
            print("💤 ساعات النوم المجلوبة: \(String(format: "%.1f", sleep / 60.0)) ساعة (\(Int(sleep)) دقيقة)")
        } else {
            print("💤 ساعات النوم المجلوبة: ⚠️ لا توجد قراءة حية لليوم")
        }
        
        print("❤️ قراءة HRV المجلوبة: \(hrvValue != nil ? "\(Int(hrvValue!)) ms" : "⚠️ لا توجد قراءة حية لليوم")")
        print("🔥 السعرات الحرارية النشطة اليوم: \(activeCalories != nil ? "\(Int(activeCalories!)) kcal" : "⚠️ لا توجد قراءة حية لليوم")")
        print("⚡️ نبضات القلب المرتفعة المتسارعة (Spikes): \(hrSpikes)")
        print("---------------------------------------------")
        
        // Privacy Guard
        guard let sleepActual = sleepMinutes,
              let hrvActual = hrvValue else {
            print("🚨 [HealthKit Engine] لا توجد بيانات كافية لحساب Energy Score.")
            return nil
        }
        
        // Calculations Configuration
        let sleepGoal = 480.0
        let hrvBaseline = 50.0
        let activeCalorieBurn = activeCalories ?? 0.0
        let calorieTarget = 500.0
        let totalSpikes = Double(hrSpikes)
        
        // Recovery
        let sleepPart = min((sleepActual / sleepGoal) * 50.0, 50.0)
        let hrvPart = min((hrvActual / hrvBaseline) * 50.0, 50.0)
        let recoveryScore = sleepPart + hrvPart
        
        // Exertion
        let caloriePart = min((activeCalorieBurn / calorieTarget) * 40.0, 40.0)
        let spikePart = totalSpikes * 20.0
        let exertionScore = caloriePart + spikePart
        
        // Energy Score
        let finalScore = recoveryScore - (exertionScore * 0.5)
        let boundedFinalScore = min(max(finalScore, 0.0), 100.0)
        
        print("🟢 Recovery: \(Int(recoveryScore)) | 🔥 Exertion: \(Int(exertionScore))")
        print("🎯 [HealthKit Engine] السكور النهائي المحسوب للطاقة: \(Int(boundedFinalScore))%\n")
        
        return boundedFinalScore
        
        #endif
    }
    // MARK: - Background Fetch Queries
    
    private func fetchLastNightSleep(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in

                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let asleepIntervals = samples
                    .filter { asleepValues.contains($0.value) }
                    .map { (start: $0.startDate, end: $0.endDate) }
                    .sorted { $0.start < $1.start }

                guard !asleepIntervals.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let maxGap: TimeInterval = 2 * 60 * 60
                var sessions: [[(start: Date, end: Date)]] = []
                var currentSession: [(start: Date, end: Date)] = []

                for interval in asleepIntervals {
                    if let last = currentSession.last {
                        let gap = interval.start.timeIntervalSince(last.end)

                        if gap <= maxGap {
                            currentSession.append(interval)
                        } else {
                            sessions.append(currentSession)
                            currentSession = [interval]
                        }
                    } else {
                        currentSession = [interval]
                    }
                }

                if !currentSession.isEmpty {
                    sessions.append(currentSession)
                }

                let bestSession = sessions.max { first, second in
                    let firstMinutes = first.reduce(0.0) {
                        $0 + $1.end.timeIntervalSince($1.start)
                    }
                    let secondMinutes = second.reduce(0.0) {
                        $0 + $1.end.timeIntervalSince($1.start)
                    }
                    return firstMinutes < secondMinutes
                }

                guard let session = bestSession else {
                    continuation.resume(returning: nil)
                    return
                }

                let totalMinutes = session.reduce(0.0) {
                    $0 + $1.end.timeIntervalSince($1.start)
                } / 60.0

                print("🛌 Sleep session intervals count: \(session.count)")
                print("🧮 Apple-like sleep minutes: \(Int(totalMinutes))")

                continuation.resume(returning: totalMinutes > 0 ? totalMinutes : nil)
            }

            healthStore.execute(query)
        }
    }
    private func fetchLastHRV(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: HKUnit(from: "ms")))
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLastRHR(predicate: NSPredicate) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: rhrType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchTodayActiveCalories(predicate: NSPredicate) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: activeCaloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                guard let stats = statistics, let sum = stats.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                let kcal = sum.doubleValue(for: .kilocalorie())
                continuation.resume(returning: kcal)
            }
            healthStore.execute(query)
        }
    }
    
    /// Checks for sudden high heart rate jumps today (e.g., periods exceeding 120 BPM while not actively logged as a workout)
    private func fetchTodayHeartRateSpikes(predicate: NSPredicate, baselineRHR: Double) async -> Int {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let hrSamples = samples as? [HKQuantitySample], !hrSamples.isEmpty else {
                    continuation.resume(returning: 0)
                    return
                }
                
                // Define a "spike" threshold: e.g., 40+ BPM over resting heart rate, or a static high exertion limit like 130 BPM
                let spikeThreshold = max(baselineRHR + 45.0, 120.0)
                
                let uniqueSpikePeriods = hrSamples.filter { sample in
                    let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    return bpm >= spikeThreshold
                }
                
                // Return a compressed count (representing instances or distinct high-stress time windows)
                // If they have sustained high HR, we don't want to register 500 individual samples as 500 spikes.
                // We count how many times it crossed into spike territory by grouping samples within close proximity.
                let count = uniqueSpikePeriods.count > 0 ? min(uniqueSpikePeriods.count / 4, 3) : 0
                continuation.resume(returning: count == 0 && uniqueSpikePeriods.count > 0 ? 1 : count)
            }
            healthStore.execute(query)
        }
    }
}
