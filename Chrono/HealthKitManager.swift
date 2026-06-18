//
//  HealthKitManager.swift
//  Chrono
//
//  Updated Energy Formula:
//  Morning Recovery + Energy Drain
//

import Foundation
import HealthKit
import Combine

struct SleepScoreResult {
    let totalScore: Double
    let durationScore: Double
    let timingScore: Double
    let interruptionScore: Double
    let sleepMinutes: Double
    let usesTiming: Bool
}

struct EnergyInsights {
    let sleepScore: Double
    let sleepMinutes: Double
    let durationScore: Double
    let timingScore: Double
    let interruptionScore: Double
    let usesSleepSchedule: Bool

    let hrv: Double
    let hrvBaseline: Double
    let hrvReadinessScore: Double

    let morningRecovery: Double
    let activeCalories: Double
    let energyDrain: Double
    let baseEnergy: Double
}


class HealthKitManager: ObservableObject {

    let healthStore = HKHealthStore()
    @Published private(set) var latestInsights: EnergyInsights?

    // MARK: - Health Types to Read
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let typesToRead: Set<HKObjectType> = [
            sleepType,
            hrvType,
            activeCaloriesType
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            return true
        } catch {
            print("HealthKit Authorization Failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Energy Score

    func calculateLiveEnergyScore() async -> Double? {

        #if targetEnvironment(simulator)
        print("ℹ️ [HealthKit Engine] Running on Simulator - Returning empty/nil to trigger empty state.")
        return nil
        #else

        print("\n📊 [HealthKit Engine] Starting Morning Recovery + Energy Drain calculation...")

        let now = Date()
        let calendar = Calendar.current

        let thirtySixHoursAgo = calendar.date(byAdding: .hour, value: -36, to: now)!
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now)!

        let sleepPredicate = HKQuery.predicateForSamples(withStart: thirtySixHoursAgo, end: now, options: [])
        let hrvRecentPredicate = HKQuery.predicateForSamples(withStart: thirtySixHoursAgo, end: now, options: [])
        let hrvBaselinePredicate = HKQuery.predicateForSamples(withStart: fourteenDaysAgo, end: now, options: [])
        let todayPredicate = HKQuery.predicateForSamples(withStart: calendar.startOfDay(for: now), end: now, options: [])

        /*
         مهم:
         حالياً نخلي expectedBedtimeHour = nil
         لأنك قلتي إنك ما حاطة Sleep Schedule، بس تشغلين Sleep Focus.
         
         إذا بعدين خليتوا المستخدم يدخل وقت نوم متوقع، غيريها مثلاً:
         let expectedBedtimeHour: Double? = 23.0
        */
        let expectedBedtimeHour: Double? = nil
        let sleepGoalMinutes = 480.0

        let sleepResult = await fetchLastNightSleepScore(
            predicate: sleepPredicate,
            sleepGoalMinutes: sleepGoalMinutes,
            expectedBedtimeHour: expectedBedtimeHour
        )

        let hrvValue = await fetchLastHRV(predicate: hrvRecentPredicate)
        let hrvBaseline = await fetchAverageHRV(predicate: hrvBaselinePredicate)
        let activeCalories = await fetchTodayActiveCalories(predicate: todayPredicate) ?? 0.0

        print("--------- 🩺 Current Sensor Report ---------")

        if let sleep = sleepResult {
            print("💤 Sleep Score: \(Int(sleep.totalScore))/100")

            if sleep.usesTiming {
                print("   Mode: With Sleep Schedule")
                print("   Duration: \(Int(sleep.durationScore))/50 | Timing: \(Int(sleep.timingScore))/30 | Interruptions: \(Int(sleep.interruptionScore))/20")
            } else {
                print("   Mode: No Sleep Schedule")
                print("   Duration: \(Int(sleep.durationScore))/70 | Timing: skipped | Interruptions: \(Int(sleep.interruptionScore))/30")
            }

            print("   Sleep Minutes: \(Int(sleep.sleepMinutes)) min")
        } else {
            print("💤 Sleep Score: ⚠️ No sleep data found")
        }

        print("❤️ HRV: \(hrvValue != nil ? "\(Int(hrvValue!)) ms" : "⚠️ No HRV data")")
        print("📈 HRV Baseline: \(hrvBaseline != nil ? "\(Int(hrvBaseline!)) ms" : "⚠️ No baseline, fallback will be used")")
        print("🔥 Active Calories Today: \(Int(activeCalories)) kcal")
        print("-------------------------------------------")

        guard let sleepResult,
              let hrvActual = hrvValue else {
            print("🚨 [HealthKit Engine] Not enough data to calculate Energy Score.")
            return nil
        }

        let sleepScore = sleepResult.totalScore

        let baseline = max(hrvBaseline ?? 50.0, 1.0)
        let hrvScore = min((hrvActual / baseline) * 100.0, 120.0)

        let morningRecovery = (sleepScore * 0.70) + (hrvScore * 0.30)

        let energyDrain = activeCalories / 25.0

        let baseEnergy = morningRecovery - energyDrain
        let boundedEnergy = min(max(baseEnergy, 0.0), 100.0)

        print("🟢 Morning Recovery: \(Int(morningRecovery))")
        print("🔥 Energy Drain: \(Int(energyDrain))")
        print("🎯 Base Energy Score: \(Int(boundedEnergy))%\n")

        let insights = EnergyInsights(
            sleepScore: sleepScore,
            sleepMinutes: sleepResult.sleepMinutes,
            durationScore: sleepResult.durationScore,
            timingScore: sleepResult.timingScore,
            interruptionScore: sleepResult.interruptionScore,
            usesSleepSchedule: sleepResult.usesTiming,
            hrv: hrvActual,
            hrvBaseline: baseline,
            hrvReadinessScore: hrvScore,
            morningRecovery: morningRecovery,
            activeCalories: activeCalories,
            energyDrain: energyDrain,
            baseEnergy: boundedEnergy
        )

        await MainActor.run {
            self.latestInsights = insights
        }
        
        return boundedEnergy

        #endif
    }

    // MARK: - Sleep Score

    private func fetchLastNightSleepScore(
        predicate: NSPredicate,
        sleepGoalMinutes: Double,
        expectedBedtimeHour: Double?
    ) async -> SleepScoreResult? {
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in

                guard let samples = samples as? [HKCategorySample],
                      !samples.isEmpty else {
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

                // Groups close sleep stages into one sleep session.
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

                guard let session = bestSession,
                      let firstInterval = session.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let sleepMinutes = session.reduce(0.0) {
                    $0 + $1.end.timeIntervalSince($1.start)
                } / 60.0

                guard sleepMinutes > 0 else {
                    continuation.resume(returning: nil)
                    return
                }

                // Counts awake gaps of 5 minutes or more.
                var interruptionCount = 0

                if session.count > 1 {
                    for index in 1..<session.count {
                        let previousEnd = session[index - 1].end
                        let currentStart = session[index].start
                        let gapMinutes = currentStart.timeIntervalSince(previousEnd) / 60.0

                        if gapMinutes >= 5 {
                            interruptionCount += 1
                        }
                    }
                }

                let usesTiming = expectedBedtimeHour != nil

                let durationScore: Double
                let timingScore: Double
                let interruptionScore: Double

                if let expectedBedtimeHour = expectedBedtimeHour {

                    // User has a Sleep Schedule / expected bedtime.
                    // Duration: 50 | Timing: 30 | Interruptions: 20

                    durationScore = min(
                        (sleepMinutes / sleepGoalMinutes) * 50.0,
                        50.0
                    )

                    let bedtimeMinutes = Self.minutesSinceMidnight(firstInterval.start)
                    let targetBedtimeMinutes = expectedBedtimeHour * 60.0
                    let timingDifference = Self.circularMinuteDifference(
                        bedtimeMinutes,
                        targetBedtimeMinutes
                    )

                    // Every 15 minutes away from the expected bedtime removes 1 point.
                    timingScore = max(
                        30.0 - (timingDifference / 15.0),
                        0.0
                    )

                    interruptionScore = max(
                        20.0 - (Double(interruptionCount) * 4.0),
                        0.0
                    )

                } else {

                    // No Sleep Schedule:
                    // Keep Apple's normal 50 / 30 / 20 structure.
                    // Until we calculate the user's usual bedtime from past nights,
                    // give neutral timing points instead of removing Timing entirely.

                    durationScore = min(
                        (sleepMinutes / sleepGoalMinutes) * 50.0,
                        50.0
                    )

                    timingScore = 24.0

                    interruptionScore = max(
                        20.0 - (Double(interruptionCount) * 4.0),
                        0.0
                    )
                }

                let totalScore = min(
                    durationScore + timingScore + interruptionScore,
                    100.0
                )

                print("🛌 Sleep session intervals count: \(session.count)")
                print("🧮 App Sleep Score: \(Int(totalScore))")

                continuation.resume(
                    returning: SleepScoreResult(
                        totalScore: totalScore,
                        durationScore: durationScore,
                        timingScore: timingScore,
                        interruptionScore: interruptionScore,
                        sleepMinutes: sleepMinutes,
                        usesTiming: usesTiming
                    )
                )
            }

            healthStore.execute(query)
        }
    }
    private static func minutesSinceMidnight(_ date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
    }

    private static func circularMinuteDifference(_ a: Double, _ b: Double) -> Double {
        let dayMinutes = 24.0 * 60.0
        let difference = abs(a - b)
        return min(difference, dayMinutes - difference)
    }

    // MARK: - HRV

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

                continuation.resume(
                    returning: sample.quantity.doubleValue(for: HKUnit(from: "ms"))
                )
            }

            healthStore.execute(query)
        }
    }

    private func fetchAverageHRV(predicate: NSPredicate) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrvType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                guard let average = statistics?.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(
                    returning: average.doubleValue(for: HKUnit(from: "ms"))
                )
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Active Calories

    private func fetchTodayActiveCalories(predicate: NSPredicate) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeCaloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let stats = statistics,
                      let sum = stats.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }

                continuation.resume(
                    returning: sum.doubleValue(for: .kilocalorie())
                )
            }

            healthStore.execute(query)
        }
    }
}
