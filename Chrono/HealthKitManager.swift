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
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

    // MARK: - Energy Score Constants
    private let sleepGoalMinutes = 480.0      // 8 hours
    private let hrvBaselineMs = 50.0          // temporary baseline
    private let calorieTargetKcal = 400.0     // daily active calorie target

    /// Requests access to Apple Health
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let typesToRead: Set<HKObjectType> = [
            sleepType,
            hrvType,
            activeEnergyType
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            return true
        } catch {
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            return false
        }
    }

    /// The Core Math Matrix: Fetches metrics and computes the Energy Score
    func calculateLiveEnergyScore() async -> Double? {

        #if targetEnvironment(simulator)
        print("ℹ️ [HealthKit Engine] Running on Simulator - Returning nil to show inactive empty state.")
        return nil
        #else

        print("\n📊 [HealthKit Engine] جاري بدء فحص بيانات الطاقة...")

        let now = Date()
        let calendar = Calendar.current

        // Sleep + HRV: last 36 hours عشان يغطي نوم الليلة الماضية
        let thirtySixHoursAgo = calendar.date(byAdding: .hour, value: -36, to: now)!
        let generalPredicate = HKQuery.predicateForSamples(withStart: thirtySixHoursAgo, end: now, options: [])

        let sleepMinutes = await fetchLastNightSleep(predicate: generalPredicate)
        let hrvValue = await fetchLastHRV(predicate: generalPredicate)

        // Active Calories: من بداية اليوم إلى الآن
        let startOfDay = calendar.startOfDay(for: now)
        let todayPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: [])
        let activeCalories = await fetchActiveCalories(predicate: todayPredicate)

        print("--------- 🩺 تقرير المستشعرات الحالية ---------")
        if let sleep = sleepMinutes {
            print("💤 Sleep: \(String(format: "%.1f", sleep / 60.0))h (\(Int(sleep)) min)")
        } else {
            print("💤 Sleep: ⚠️ لا توجد قراءة")
        }

        print("❤️ HRV: \(hrvValue != nil ? "\(Int(hrvValue!)) ms" : "⚠️ لا توجد قراءة")")
        print("🔥 Active Calories: \(activeCalories != nil ? "\(Int(activeCalories!)) kcal" : "⚠️ لا توجد قراءة")")
        print("---------------------------------------------")

        // لو كل الداتا فاضية: لا نطلع رقم وهمي
        if sleepMinutes == nil && hrvValue == nil && activeCalories == nil {
            print("🚨 [HealthKit Engine] لا توجد بيانات كافية لحساب Energy Score.")
            return nil
        }

        // Fallback للبيانات الناقصة فقط
        let finalSleep = sleepMinutes ?? sleepGoalMinutes
        let finalHRV = hrvValue ?? hrvBaselineMs
        let finalActiveCalories = activeCalories ?? 0.0

        // Recovery =
        // (Sleep Actual / Sleep Goal × 50) + (HRV Actual / HRV Baseline × 50)
        let sleepRecovery = min((finalSleep / sleepGoalMinutes) * 50.0, 50.0)
        let hrvRecovery = min((finalHRV / hrvBaselineMs) * 50.0, 50.0)
        let recovery = sleepRecovery + hrvRecovery

        // Exertion =
        // (Active Calories / Calorie Target × 40)
        let exertion = min((finalActiveCalories / calorieTargetKcal) * 40.0, 40.0)

        // Energy Score = Recovery − (Exertion * 0.5)
        let energyScore = recovery - (exertion * 0.5)
        let finalRoundedScore = min(max(energyScore, 0.0), 100.0)

        print("🟢 Recovery: \(Int(recovery)) | 🔥 Exertion: \(Int(exertion))")
        print("🎯 [HealthKit Engine] السكور النهائي: \(Int(finalRoundedScore))%\n")
        return finalRoundedScore

        #endif
    }

    // Compatibility wrapper if any old code still calls this name
    func calculateMorningBaseline() async -> Double? {
        return await calculateLiveEnergyScore()
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

                // نقسم النوم إلى جلسات، لو فيه فراغ أكثر من ساعتين نعتبرها جلسة ثانية
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

                // نأخذ أطول جلسة نوم، غالبًا هي نوم الليل
                let bestSession = sessions.max { first, second in
                    let firstMinutes = first.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
                    let secondMinutes = second.reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
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
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let hrvInMs = sample.quantity.doubleValue(for: HKUnit(from: "ms"))
                continuation.resume(returning: hrvInMs)
            }

            healthStore.execute(query)
        }
    }

    private func fetchActiveCalories(predicate: NSPredicate) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                let kcal = sum.doubleValue(for: .kilocalorie())
                continuation.resume(returning: kcal > 0 ? kcal : nil)
            }

            healthStore.execute(query)
        }
    }
}
